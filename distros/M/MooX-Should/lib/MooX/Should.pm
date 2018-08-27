package MooX::Should;

# ABSTRACT: optional type restrictions for Moo attributes

use Moo       ();
use Moo::Role ();

use Devel::StrictMode;

our $VERSION = 'v0.1.2';

sub import {
    my ($class) = @_;

    my $target = caller;

    my $installer =
      $target->isa("Moo::Object")
      ? \&Moo::_install_tracked
      : \&Moo::Role::install_tracked;

    if ( my $has = $target->can('has') ) {

        my $wrapper = sub {
            my ( $name, %args ) = @_;

            if ( my $should = delete $args{should} ) {
                $args{isa} = $should if STRICT;
            }

            return $has->( $name => %args );
        };

        $installer->( $target, "has", $wrapper );

    }

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::Should - optional type restrictions for Moo attributes

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

  use Moo;

  use MooX::Should;
  use Types::Standard -types;

  has thing => (
    is     => 'ro',
    should => Int,
  );

=head1 DESCRIPTION

This module is basically a shortcut for

  use Devel::StrictMode;
  use PerlX::Maybe;

  has thing => (
          is  => 'ro',
    maybe isa => STRICT ? Int : undef,
  );

It allows you to completely ignore any type restrictions on L<Moo>
attributes at runtime, or to selectively enable them.

Note that you can specify a (weaker) type restriction for an attribute:

  use Types::Common::Numeric qw/ PositiveInt /;
  use Types::Standard qw/ Int /;

  has thing => (
    is     => 'ro',
    isa    => Int,
    should => PositiveInt,
  );

but this is equivalent to

  use Devel::StrictMode;

  has thing => (
    is     => 'ro',
    isa    => STRICT ? PositiveInt : Int,
  );

=head1 SEE ALSO

=over

=item *

L<Devel::StrictMode>

=item *

L<PerlX::Maybe>

=back

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/MooX-Should>
and may be cloned from L<git://github.com/robrwo/MooX-Should.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/MooX-Should/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
