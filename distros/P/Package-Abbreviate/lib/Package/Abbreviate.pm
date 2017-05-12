package Package::Abbreviate;

use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

sub new {
  my ($class, $max, $opts) = @_;

  croak "requires max length of abbreviation" unless $max && $max =~ /^\d+$/;

  bless {%{$opts || {}}, max => $max}, $class;
}

sub abbr {
  my ($self, @packages) = @_;

  return $self->_abbr($packages[0]) if @packages == 1;

  my @abbreviation = map { $self->_abbr($_) } @packages;

  # validation: everything should be unique
  # (as long as packages are unique)
  my (%seen, $num_of_dupes);
  for (@abbreviation) {
    $num_of_dupes++ if $seen{$_}++;
  }
  if ($num_of_dupes) {
    %seen = ();
    for (@packages) {
      $num_of_dupes-- if $seen{$_}++;
    }
    $self->_error("Max length ($self->{max}) was too small and found duplicated abbreviations") if $num_of_dupes;
  }
  return @abbreviation;
}

sub _abbr {
  my ($self, $package) = @_;
  my $max = $self->{max};
  my $excess = length($package) - $max;
  return $package unless $excess > 0;

  my $abbreviation = $package;
  while($abbreviation =~ /(?:^|::)([A-Z]+[^A-Z][^:]+::)/) {
    my $part = $1;
    $excess -= (my $abbr = ucfirst $part) =~ s/[^A-Z:]//g;
    $abbr = lcfirst $abbr if $part =~ /^[a-z]/;
    $abbreviation =~ s/$part/$abbr/;
    return $abbreviation unless $excess > 0;
  }
  if ($self->{eager}) {
    my @parts = split /::/, $abbreviation;
    my $n = int(($excess + 1) / 2);
    if ($n < @parts - 1) {
      $abbreviation = join '::', join('', @parts[0..$n]), @parts[$n+1..@parts-1];
    } else {
      $excess -= $parts[-1] =~ s/[^A-Z]//g;
      if ($excess > 0) {
        $abbreviation = join '', @parts;
      } else {
        $abbreviation = join '::', @parts;
      }
    }
  }

  $self->_error("Max length ($self->{max}) was too small to abbreviate $package") if length($abbreviation) > $max;

  return $abbreviation;
}

sub _error {
  my ($self, $message) = @_;
  croak $message if $self->{croak};
  carp $message;
}

1;

__END__

=head1 NAME

Package::Abbreviate - shorten package names

=head1 SYNOPSIS

    use Package::Abbreviate;
    
    my $pkg = "Foo::Bar::TooLong::PackageName";
    
    # no need to abbreviate!
    my $p = Package::Abbreviate->new(30);
    printf '%30s', $p->abbr($pkg); # Foo::Bar::TooLong::PackageName
    
    # a bit shorter
    my $p = Package::Abbreviate->new(28);
    printf '%28s', $p->abbr($pkg); # F::Bar::TooLong::PackageName
    
    # even shorter
    my $p = Package::Abbreviate->new(24);
    printf '%24s', $p->abbr($pkg); # F::B::TL::PackageName
    
    # even! ...oops
    my $p = Package::Abbreviate->new(20);
    printf '%20s', $p->abbr($pkg); # spits a warning
    
    # we can do it more eagerly with an option
    my $p = Package::Abbreviate->new(20, {eager => 1});
    printf '%20s', $p->abbr($pkg); # FB::TL::PackageName
    
    # more eagerly
    my $p = Package::Abbreviate->new(16, {eager => 1});
    printf '%16s', $p->abbr($pkg); # F::B::TL::PN
    
    # even more!
    my $p = Package::Abbreviate->new(10, {eager => 1});
    printf '%10s', $p->abbr($pkg); # FBTLPN
    
    # oops, there's nothing left to cut...
    my $p = Package::Abbreviate->new(5, {eager => 1});
    printf '%5s', $p->abbr($pkg); # spits a warning

=head1 DESCRIPTION

When you make a big table that contains a lot of data with (long) package names, you might want to shorten some of them. However, just trimming them with C<sprintf> or C<substr> may not work for you.

Package::Abbreviate shortens package names, but also tries not to do too much.

=head1 METHODS

=head2 new

takes a max length of abbreviations, and an optional hash reference to configure.

=over 4

=item eager

lets Package::Abbreviate to shorten the basename and/or omit colons between monikers.

=item croak

croaks if an error occurs.

=back

=head2 abbr

takes one or more package names and returns shortened ones.

If you pass more than one package names, Package::Abbreviate also tests if duplicated names are not generated.

=head1 SEE ALSO

L<Lingua::Abbreviate::Hierarchy>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
