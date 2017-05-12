package Switch::Perlish::Smatch::Undef;

$VERSION = '1.0.0';

use strict;
use warnings;

use Carp 'croak';

## DESC - Return false as $m is already defined.
sub _VALUE { return }

## DESC - Return true as $m is already undefined.
sub _UNDEF { return 1 }

## DESC - Check if $$m is undef.
sub _SCALAR {
  my($t, $m) = @_;
  return !defined($$m);
}

## DESC - Check for an undef in @$m.
sub _ARRAY {
  my($t, $m) = @_;
  !defined and return 1
    for @$m;
  return;
}

## DESC - Check for an undefined value in %$m (better suggestions welcome).
sub _HASH {
  my($t, $m) = @_;
  !defined and return 1
    for values %$m;
  return;
}

## DESC - Pass undef to &$m (to be consistent with other CODE comparators).
sub _CODE {
  my($t, $m) = @_;
  return $m->($t);
}

## DESC - croak("Can't compare undef with OBJECT") # Suggestions welcome.
sub _OBJECT {
  croak("Can't compare undef with OBJECT");
}

## DESC - croak("Can't compare undef with Regexp") # Suggestions welcome.
sub _Regexp {
  croak("Can't compare undef with Regexp");
}

Switch::Perlish::Smatch->register_package( __PACKAGE__, 'UNDEF' );

1;

=pod

=head1 NAME

Switch::Perlish::Smatch::Undef - The C<UNDEF> comparatory category package.

=head1 VERSION

1.0.0 - Initial release.

=head1 DESCRIPTION

This package provides the default implementation for the C<UNDEF> comparator
category. For more information on the comparator implementation see.
L<Switch::Perlish::Smatch::Comparators/"Undef">.

=head1 SEE. ALSO

L<Switch::Perlish::Smatch>.

=head1 AUTHOR

Dan Brook C<< <mr.daniel.brook@gmail.com> >>

=head1 COPYRIGHT

Copyright (c) 2006, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same
terms as Perl itself.

=cut
