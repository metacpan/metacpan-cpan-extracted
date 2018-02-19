package Phone::Number;

use strict;
use warnings;
no if $^V ge v5.18.0 && $^V lt v5.19.0, warnings => "experimental";
use 5.10.0;

=head1 NAME

Phone::Number - Module to hold a phone number from a UK-centric
point of view.

head1 VERSION

Version v1.1.2

=cut

use version 0.77; our $VERSION = qv('v1.1.2');

use Carp;

use experimental qw(switch);
use overload q("") => 'formatted';

=head1 SYNOPSYS

    use Phone::Number;
    
    my $num = new Phone::Number('02002221666');
    print $num->formatted;    # 020 0222 1666
    print $num->packed;       # 02002221666
    print $num->number;       # +442002221666
    print $num->plain;        # 442002221666
    print $num->uk ? "yes" : "no"; # yes

=head1 EXPORT

Nothing is exported

=head1 ROUTINES

=head2 new

Creates a new, immutable object using any unambiguous phone
number format.

    my $num = new Phone::Number('02002221666');
    my $num = new Phone::Number('2002221666');
    my $num = new Phone::Number('442002221666');
    my $num = new Phone::Number('+442002221666');
    my $new = new Phone::Number($num);

=cut

# Passed a string or a Number object.  If the latter, simply returns it.
sub new
{
    my $class = shift;
    my $number = shift or croak "No number passed to new $class";
    return $number if ref $number && $number->isa($class);
    $number =~ s/^\s*(.*?)\s*$/$1/;	# trim leading/trailing spaces
    $number =~ s/\D//g;			# throw away non-digits
    $number =~ s/^44/0/;		# change leading 44 into 0
    $number =~ s/^(?=[1-9])/00/;	# it still starts with a 1-9, add 00
    my $self = {};
    $self->{raw} = $number;
    $self->{valid} = $number =~ /^0[123578]\d{8,9}$/;
    my $formatted;
    given ($number)
    {
	when (/^02/)
	{
	    ($formatted = $number) =~ s/^(\d{3})(\d{4})(\d*)/$1 $2 $3/;
	}
	when (/^03/)
	{
	    ($formatted = $number) =~ s/^(\d{4})(\d{3})(\d*)/$1 $2 $3/;
	}
	when (/^01\d?1/ || /^08[47]/) {
	    ($formatted = $number) =~ s/^(\d{4})(\d{3})(\d*)/$1 $2 $3/;
	}
	when (/^0[85]0/) {
	    ($formatted = $number) =~ s/^(\d{4})(\d{3})(\d*)/$1 $2 $3/;
	}
	when (/^0(?!0)/) {
	    ($formatted = $number) =~ s/^(\d{5})(\d*)/$1 $2/;
	}
	default {
	    $formatted = $number;
	}
    }
    $self->{formatted} = $formatted;
    $number =~ s/^00/+/;
    $number =~ s/^0/+44/;
    $self->{number} = $number;
    bless $self, $class;
}

=head2 formatted

Returns the number formatted with leading 0 and spaces.

This can be used for displaying the number in "standard" format.

The raw object stringifies to the formatted version.

=cut

sub formatted
{
    my $self = shift;
    return $self->{formatted};
}

=head2 packed

Returns the number with a leading 0 but no spaces.

This can be useful for databases but see L</plain> below.

=cut

sub packed
{
    my $self = shift;
    (my $packed = $self->formatted) =~ s/\s+//g;
    return $packed;
}

=head2 number

Returns the number in international format starting with +.

=cut

sub number
{
    my $self = shift;
    return $self->{number};
}

=head2 plain

Returns the number in international format without the +.

This is usually the best way to store the number onto a database.

=cut

sub plain
{
    my $self = shift;
    (my $plain = $self->{number}) =~ s/^\+//;
    return $plain;
}

=head2 uk

Returns a boolean: true if it is a valid UK number

=cut

sub uk
{
    my $self = shift;
    return $self->{valid};
}

=head1 AUTHOR

Cliff Stanford, C<< <cpan@may.be> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-phone-number at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Phone-Number>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Phone::Number

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Cliff Stanford.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut



1;
