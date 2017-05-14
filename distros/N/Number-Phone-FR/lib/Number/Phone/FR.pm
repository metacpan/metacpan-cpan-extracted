use utf8;
use strict;
use warnings;

package Number::Phone::FR;

# $VERSION is limited to 2 digits after the dot
# Other digits are reserved for ARCEP data versonning
# in Number::Phone::FR::Full
our $VERSION = '0.09';

use Number::Phone;
use parent 'Number::Phone';

use Carp;
use Scalar::Util 'blessed';

my %pkg2impl;

# Select the implementation to use via "use Number::Phone::FR"

sub import
{
    my $class = shift;
    croak "invalid sub-class" unless $class->isa(__PACKAGE__);
    if ($class eq __PACKAGE__) {
        if (@_) {
            $class = $_[0];
            $class =~ s/^:?(.)/\U$1/;
            substr($class, 0, 0) = __PACKAGE__.'::';

            my $level = 0;
            my $pkg;
            while (($pkg = (caller $level)[0]) =~ /^Number::Phone(?:::|$)/) {
                $level++;
            }
            $pkg2impl{$pkg} = $class;

            # Load the class
            eval "require $class; 1" or croak "$@\n";
            $class->isa(__PACKAGE__) or croak "$class is not a valid class";
        }
    } else {
        #croak "unexpected arguments for import" if @_;
        my $pkg = (caller)[0];
        croak "$class is private" unless $pkg =~ m/^Number::Phone(?:::|$)/;
        $pkg2impl{$pkg} = $class;
    }
}

#END {
#    foreach (sort keys %pkg2impl) {
#        print STDERR "# $_ => $pkg2impl{$_}\n";
#    }
#}


# Select the implementation based on $pkg2impl
sub _get_class
{
    my ($class) = @_;
    return $class if defined $class && $class ne __PACKAGE__;
    my $level = 0;
    my ($pkg, $impl);
    while ($pkg = (caller $level)[0]) {
        $impl = $pkg2impl{$pkg};
        return $impl if defined $impl;
        $level++;
    }
    # Default implementation
    return __PACKAGE__;
}


use constant RE_SUBSCRIBER =>
  qr{
    \A
    (?:
       \+33          # Préfixe international (+33 numéro)
     | (?:3651)?
       (?:
         [04789]     # Transporteur par défaut (0) ou Sélection du transporteur
       | 16 [0-9]{2} # Sélection du transporteur
       ) (?:033)?    # Préfixe international (0033 numéro)
    ) ([1-9][0-9]{8})  # Numéro de ligne
    \z
  }xs;

use constant RE_FULL =>
  qr{
  \A (?:
    1 (?:
        0[0-9]{2}  # Opérateur
      | 5          # SAMU
      | 7          # Police/gendarmerie
      | 8          # Pompiers
      | 1 (?:
            2      # Numéro d'urgence européen
          | 5      # Urgences sociales
	  | 6000          # 116000 : Enfance maltraitée
          | 8[0-9]{3}     # 118XYZ : Renseignements téléphoniques
	  | 9      # Enfance maltraitée
	  )
      )
  | 3[0-9]{3}
  | (?:
       \+33          # Préfixe international (+33 numéro)
     | (?:3651)?     # Préfixe d'anonymisation
       (?:
         [04789]     # Transporteur par défaut (0) ou Sélection du transporteur
       | 16 [0-9]{2} # Sélection du transporteur
       ) (?:033)?    # Préfixe international (0033 numéro)
    ) [1-9][0-9]{8}  # Numéro de ligne
  ) \z
  }xs;




sub country_code() { 33 }

# Number::Phone's implementation of country() does not yet allow
# clean subclassing so we explicitely implement it here
sub country() { 'FR' }


sub new
{
    my $class = shift;
    my $number = shift;
    $class = ref $class if ref $class;

    $class = _get_class($class);

    croak "No number given to ".__PACKAGE__."->new()\n" unless defined $number;
    croak "Invalid phone number (scalar expected)" if ref $number;

    my $num = $number;
    $num =~ s/[^+0-9]//g;
    return Number::Phone->new("+$1") if $num =~ /\A(?:\+|00)((?:[^3]|3[^3]).*)\z/;

    return is_valid($number) ? bless(\$num, $class) : undef;
}


sub is_valid
{
    my ($number) = (@_);
    return 1 if blessed($number) && $number->isa(__PACKAGE__);

    my $class = _get_class();
    return $number =~ $class->RE_FULL;
}


sub is_allocated
{
    undef
}

sub is_in_use
{
    undef
}

sub _num(\@)
{
    my $args = shift;
    my $num = shift @$args;
    my $class = ref $num;
    if ($class) {
	$num = ${$num};
    } else {
	$class = _get_class();
	$num = shift @$args;
    }
    return ($class, $num);
}

# Vérifie les chiffres du numéro de ligne
# Les numéros spéciaux ne matchent pas
sub _check_line
{
    my ($class, $num) = _num(@_);
    my @matches = ($num =~ $class->RE_SUBSCRIBER);
    return 0 unless @matches;
    my $line = (grep { defined } @matches)[0];
    return 1 if $line =~ shift;
    undef
}

sub is_geographic
{
    return _check_line(@_, qr/\A[1-5].{8}\z/)
}

sub is_fixed_line
{
    return _check_line(@_, qr/\A[1-5].{8}\z/)
}

sub is_mobile
{
    return _check_line(@_, qr/\A[67].{8}\z/)
}

sub is_pager
{
    undef
}

sub is_ipphone
{
    return _check_line(@_, qr/\A9/)
}

sub is_isdn
{
    undef
}

sub is_tollfree
{
    #return 1 
    # FIXME Gérer les préfixes
    return 0 unless $_[1] =~ /\A08[0-9]{8}\z/;
    undef
}

sub is_specialrate
{
    # FIXME Gérer les préfixes
    return 0 unless $_[1] =~ /\A08[0-9]{8}\z/;
    1
}

sub is_adult
{
    return 0 unless _check_line(@_, qr/\A8/);
    undef
}

sub is_personal
{
    undef
}

sub is_corporate
{
    undef
}

sub is_government
{
    undef
}

sub is_international
{
    undef
}

sub is_network_service
{
    my ($class, $num) = _num(@_);
    # Les services réseau sont en direct : jamais de préfixe
    ($num =~ /\A1(?:|[578]|0[0-9]{2}|1(?:[259]|6000|8[0-9]{3}))\z/) ? 1 : 0
}

sub areacode
{
    undef
}

sub areaname
{
    undef
}

sub location
{
    undef
}

sub subscriber
{
    my ($class, $num) = _num(@_);
    my @m = ($num =~ $class->RE_SUBSCRIBER);
    return undef unless @m;
    @m = grep { defined } @m;
    $m[0];
}

my %length_to_format = (
    # 2 => as is
    4 => sub { s/\A(..)(..)/$1 $2/ },
    6 => sub { s/\A(...)(...)/$1 $2/ },
    10 => sub { s/(\d\d)(?=.)/$1 /g },
    13 => sub {
	       s/\A(00)(33)(.)(..)(..)(..)(..)\z/+$2 $3 $4 $5 $6 $7/
	    || s/\A(....)(.)(..)(..)(..)(..)\z/+33 $1 $2 $3 $4 $5 $6/
	  },
    14 => sub { s/\A(....)(..)(..)(..)(..)(..)\z/$1 $2 $3 $4 $5 $6/ },
    12 => sub { s/\A(\+33)(.)(..)(..)(..)(..)\z/$1 $2 $3 $4 $5 $6/ },
    16 => sub { s/\A(\+33)(....)(.)(..)(..)(..)(..)\z/$1 $2 $3 $4 $5 $6 $7/ },
);

sub format
{
    my ($class, $num) = _num(@_);
    my $l = length $num;
    my $fmt = $length_to_format{$l};
    return defined $fmt
	?   do {
		local $_ = $num;
		$fmt->();
		$_;
	    }
	: $num;
}



package Number::Phone::FR::Simple;

use parent 'Number::Phone::FR';

BEGIN {
    $INC{'Number/Phone/FR/Simple.pm'} = __FILE__;
}

1;
__END__
=head1 NAME

Number::Phone::FR - Phone number information for France (+33)

=head1 SYNOPSIS

Use C<Number::Phone::FR> through C<L<Number::Phone>>:

    use Number::Phone;
    my $num = Number::Phone->new('+33148901515');

Select a particular implementation of C<Number::Phone::FR> for this package:

    use Number::Phone::FR 'Full';
    my $num = Number::Phone->new('+33148901515');

    use Number::Phone::FR 'Simple';
    my $num = Number::Phone->new('+33148901515');

One-liners:

    perl -MNumber::Phone "-Esay Number::Phone->new(q!+33148901515!)->format"
    perl -MNumber::Phone::FR=Full "-Esay Number::Phone->new(q!+33148901515!)->operator"
    perl -MNumber::Phone::FR=Full "-Esay Number::Phone::FR->new(q!3949!)->operator"

=head1 DESCRIPTION

This is a subclass of L<Number::Phone> that provides information for phone
numbers in France.

I<B<Note:> Cette documentation est E<eacute>galement disponible en
franE<ccedil>ais dans L<POD2::FR::Number::Phone::FR>.>

Two implementations are provided:

=over 4

=item *

C<Simple>

=item *

C<Full>: a more complete implementation that does checks based on information
from the ARCEP.

=back

The implementation is selected for a particular package by importing the
Number::Phone::FR package with the selected implementation.
All Number::Phone::FR objects created from this package (either indirectly
with Number::Phone->new or explicitely with Number::Phone::FR->new) will be
created using this implementation.

=head1 DATA SOURCES

L<https://extranet.arcep.fr/portail/Op%C3%A9rateursCE/Num%C3%A9rotation.aspx#PUB>

The tools for rebuilding the Number-Phone-FR CPAN distribution with updated
data are included in the distribution:

    perl Build.PL
    ./Build update
    perl Build.PL
    ./Build
    ./Build test
    ./Build dist

=head1 VERSIONNING

The C<Number-Phone-FR> distribution contains different modules which have
their own versions:

=over 4

=item *

Number::Phone::FR : C<m.nn> (I<major> . I<minor>)

=item *

L<Number::Phone::FR::Full> : C<m.nnyyddd> (I<major> . I<minor> I<year> I<day-of-year>)

=back

C<m.nn> is the versionning of the code. Common for the two packages.

C<yyddd> is the versionning of the ARCEP data.

=head1 SEE ALSO

=over 4

=item *

L<http://fr.wikipedia.org/wiki/Plan_de_num%C3%A9rotation_t%C3%A9l%C3%A9phonique_en_France>

=item *

L<Number::Phone>

=back

=head1 SUPPORT

(english or french)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Phone-FR>

The latest available source code (work in progress) is published on GitHub:
L<https://github.com/dolmen/p5-Number-Phone-FR>

=head1 AUTHOR

Olivier MenguE<eacute>, L<mailto:dolmen@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2010-2014 Olivier MenguE<eacute>.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.

=cut
