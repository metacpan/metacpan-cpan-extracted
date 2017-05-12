package Switch::Perlish::Smatch::Hash;

$VERSION = '1.0.0';

use strict;
use warnings;

use Switch::Perlish::Smatch 'smatch';

## Provide a wrapper sub to test against values?
## DESC - Check if $m exists as a key in %$t.
sub _VALUE {
  my($t, $m) = @_;
  return exists $t->{$m};
}

## DESC - Check for an undefined value in %$t (better suggestions welcome).
sub _UNDEF {
  my($t, $m) = @_;
  !defined and return 1
    for values %$t;
  return;
}

## DESC - Check if $m points to value in %$t.
sub _SCALAR {
  my($t, $m) = @_;
  \$_ == $m and return 1
    for values %$t;
  return;
}

## DESC - Check if an element of @$m exists as a key of %$t.
sub _ARRAY {
  my($t, $m) = @_;
  exists $t->{$_} and return 1
    for @$m;
  return;
}

## DESC - Check if a key =E<gt> value pair exists in both %$t and %$m.
sub _HASH {
  my($t, $m) = @_;
  exists $t->{$_} and smatch($t->{$_}, $m->{$_}) and return 1
    for keys %$m;
  return;
}

## DESC - Check if the return from &$m is a hash key of %$t.
sub _CODE {
  my($t, $m) = @_;
  return exists $t->{$m->()};
}

## DESC - Check if a key of %$t exists as a method of $m.
sub _OBJECT {
  my($t, $m) = @_;
  $m->can($_) and return 1
    for keys %$t;
  return;
}

## DESC - Check if any keys from %$t match $m.
sub _Regexp {
  my($t, $m) = @_;
  /$m/ and return 1
    for keys %$t;
  return;
}

Switch::Perlish::Smatch->register_package( __PACKAGE__, 'HASH' );

1;

=pod

=head1 NAME

Switch::Perlish::Smatch::Hash - The C<HASH> comparatory category package.

=head1 VERSION

1.0.0 - Initial release.

=head1 DESCRIPTION

This package provides the default implementation for the C<HASH> comparator
category. For more information on the comparator implementation see.
L<Switch::Perlish::Smatch::Comparators/"Hash">.

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
