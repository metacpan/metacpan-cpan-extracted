package MooX::TypeTiny;
use strict;
use warnings;
our $VERSION = '0.002003';
$VERSION =~ tr/_//d;

use Moo::_Utils qw(_install_modifier);

sub import {
  my $target = caller;
  require Moo;
  require Moo::Role;

  unless (Moo->is_class($target)) {
    die "MooX::TypeTiny can only be used on Moo classes.";
  }

  _install_modifier($target, 'before', ['has', 'extends', 'with'], sub {
    my $am = Moo->_accessor_maker_for($target);
    $am->does($_) or Moo::Role->apply_roles_to_object($am, $_)
      for qw(MooX::TypeTiny::Role::GenerateAccessor);

    # make sure we have our own constructor
    Moo->_constructor_maker_for($target);
  });
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

MooX::TypeTiny - Optimized type checks for Moo + Type::Tiny

=head1 SYNOPSIS

  package Some::Moo::Class;
  use Moo;
  use MooX::TypeTiny;
  use Types::Standard qw(Int);

  has attr1 => (is => 'ro', isa => Int);

=head1 DESCRIPTION

This module optimizes L<Moo> type checks when used with L<Type::Tiny> to perform
better.  It will automatically apply to isa checks and coercions that use
Type::Tiny.  Non-Type::Tiny isa checks will work as normal.

This is done by inlining the type check in a more optimal manner that is
specific to Type::Tiny rather than the general mechanism Moo usually uses.

With this module, setters with type checks should be as fast as an equivalent
check in L<Moose>.

It is hoped that eventually this type inlining will be done automatically,
making this module unnecessary.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2015 the MooX::TypeTiny L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
