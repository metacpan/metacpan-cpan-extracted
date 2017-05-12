use 5.006;
use strict;
use warnings;

package MooX::NewDefaults;

our $VERSION = '0.001002';

# ABSTRACT: Alter attribute defaults with less pain

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Sub::Exporter::Progressive -setup => {
  exports => [qw( default_for )],
  groups  => {
    default => [qw( default_for )],
  },
};

sub default_for {
  my ( $name_proto, @args ) = @_;
  my $target = caller;

  my (@name_proto) = 'ARRAY' eq ref $name_proto ? @{$name_proto} : $name_proto;

  if ( @args != 1 ) {
    require Carp;
    Carp::croak(
      sprintf q[Invalid options for %s default: Single argument expected, got %s],
      join( ', ', map { "'$_'" } @name_proto ),
      scalar @args,
    );
  }
  my $coderef;
  if ( not $coderef = $target->can('has') ) {
    require Carp;
    Carp::croak( sprintf q[Calling class %s cannot "has". Did you forget to "use Moo"?], $target, );
  }

  # Calling '->has()' directly of course doesn't work, because it doesn't expect
  # $_[0] to be a class, but the attribute name.
  #
  # The class itself is baked into $target::has during `use Moo`
  return $coderef->( [ map { "+$_" } @name_proto ], default => @args );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::NewDefaults - Alter attribute defaults with less pain

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

Concept and documentation liberally stolen from L<< C<MooseX::NewDefaults>|MooseX::NewDefaults >>

    package One;
    use Moo;

    has A => (is => 'ro', default => sub { 'say ahhh' });
    has B => (is => 'ro', default => sub { 'say whoo' });

    package Two;
    use Moo;
    use MooX::NewDefaults;

    extends 'One';

    # sugar for defining a new default
    default_for A => sub { 'say oooh' };

    # this is also legal
    default_for B => 'say oooh';

=head1 DESCRIPTION

Ever start using a package from the CPAN, only to discover that it requires
lots of subclassing and C<< has '+foo' => (default => ...) >>?  It's not
recommended Moose best practice, and it's certainly not the prettiest thing
ever, either.

That's where we come in.

This package introduces new sugar that you can use in your class,
C<< default_for >> (as seen above).

e.g.

    has '+foo' => (default => sub { 'a b c' });

...is the same as:

    default_for foo => sub { 'a b c' };

=head1 NEW SUGAR

=head2 default_for

default_for() is a shortcut to extend an attribute to give it a new default;
this default value may be any legal value for default options.

    # attribute bar defined elsewhere (e.g. superclass)
    default_for bar => 'new default';

... is the same as:

    has '+bar' => (default => 'new default');

=head1 AUTHORS

=over 4

=item *

Kent Fredric <kentnl@cpan.org>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl <cweyl@alumni.drew.edu>.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
