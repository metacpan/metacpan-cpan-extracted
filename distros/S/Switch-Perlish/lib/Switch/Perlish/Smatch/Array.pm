package Switch::Perlish::Smatch::Array;

$VERSION = '1.0.0';

use strict;
use warnings;

use Switch::Perlish::Smatch 'smatch';

## DESC - Smatch for $m in @$t.
sub _VALUE {
  my($t, $m) = @_;
  smatch($m, $_) and return 1
    for @$t;
  return;
}

## DESC - Return false as $t is already defined.
sub _UNDEF { return }

## DESC - Check if $m points to an element of @$t.
sub _SCALAR {
  my($t, $m) = @_;
  \$_ == $m and return 1
    for @$t;
  return;
}

## This also doesn't feel right.
## DESC - Smatch for an element of @$m in @$t.
sub _ARRAY {
  my($t, $m) = @_;
  for my $el (@$t) {
    smatch($el, $_) and return 1
      for @$m;
  }
  return;
}

## This is what I get for JFDI.
## DESC - Check if an element of @$t exists as a key in %$m.
sub _HASH {
  my($t, $m) = @_;
  exists $m->{$_} and return 1
    for @$t;
  return;
}

## DESC - Call &$m with @$t.
sub _CODE {
  my($t, $m) = @_;
  return $m->(@$t);
}

## More uncertainty.
## DESC - Check if an element of @$t exists as a method of $m.
sub _OBJECT {
  my($t, $m) = @_;
  $m->can($_) and return 1
    for @$t;
  return;
}

## DESC - Match $m against the elements of @$t.
sub _Regexp {
  my($t, $m) = @_;
  /$m/ and return 1
    for @$t;
  return;
}

Switch::Perlish::Smatch->register_package( __PACKAGE__, 'ARRAY' );

1;

=pod

=head1 NAME

Switch::Perlish::Smatch::Array - The C<ARRAY> comparatory category package.

=head1 VERSION

1.0.0 - Initial release.

=head1 DESCRIPTION

This package provides the default implementation for the C<ARRAY> comparator
category. For more information on the comparator implementation see.
L<Switch::Perlish::Smatch::Comparators/"Array">.

=head1 SEE. ALSO

L<Switch::Perlish::Smatch>

L<Switch::Perlish::Smatch::Comparators>

=head1 AUTHOR

Dan Brook C<< <mr.daniel.brook@gmail.com> >>

=head1 COPYRIGHT

Copyright (c) 2006, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same
terms as Perl itself.

=cut
