package Test::Deep::Matcher;

use 5.008001;
use strict;
use warnings;
use parent 'Exporter';
use Test::Deep::Matcher::DataUtil;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

our @RefMatchers = qw(
    is_scalar_ref
    is_array_ref
    is_hash_ref
    is_code_ref
    is_glob_ref
);

for my $name (@RefMatchers) {
    no strict 'refs';
    *{$name} = sub { Test::Deep::Matcher::DataUtil->new($name, @_) };
}

our @PrimitiveMatchers = qw(
    is_value
    is_string
    is_number
    is_integer
);

for my $name (@PrimitiveMatchers) {
    no strict 'refs';
    *{$name} = sub { Test::Deep::Matcher::DataUtil->new($name, @_) };
}

our @EXPORT = (
    @RefMatchers,
    @PrimitiveMatchers,
);

1;

=head1 NAME

Test::Deep::Matcher - Type check matchers for Test::Deep

=head1 SYNOPSIS

  use Test::More;
  use Test::Deep;
  use Test::Deep::Matcher;

  my $got = +{
      foo  => 'string',
      bar  => 100,
      baz  => [ 1, 2, 3 ],
      quux => { foo => 'bar' },
  };

  cmp_deeply($got, +{
      foo  => is_string,
      bar  => is_integer,
      baz  => is_array_ref,
      quux => is_hash_ref,
  });

  done_testing;

=head1 DESCRIPTION

Test::Deep::Matcher is a collection of Test::Deep type check matchers.

=head1 METHODS

=head2 Reference Matchers

=over 4

=item is_scalar_ref

Checks the value type is SCALAR reference.

=item is_array_ref

Checks the value type is ARRAY reference.

=item is_hash_ref

Checks the value type is HASH reference.

=item is_code_ref

Checks the value type is CODE reference.

=item is_glob_ref

Checks the value type is GLOB reference.

=back

=head2 Primitive Matchers

=over 4

=item is_value

Checks the value is primitive, is B<not undef>.

=item is_string

Checks the value is string, has length.

=item is_number

Checks the value is number.

=item is_integer

Checks the value is integer, is also number.

=back

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Deep>, <Data::Util>

=cut
