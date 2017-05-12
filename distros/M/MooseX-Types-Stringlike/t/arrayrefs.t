use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use MooseX::Types::Stringlike qw/Stringable Stringlike ArrayRefOfStringable ArrayRefOfStringlike/;

{
  package BlessedPath;
  use overload q{""} => sub { "${$_[0]}" };
  sub new { my ($class, $path) = @_; return bless \$path, $class; }
}

my $stringable = [ map { BlessedPath->new($_) } ('./t', './xt') ];

ok(is_ArrayRefOfStringable($stringable), 'arrayref of stringable things is a ArrayRefOfStringable');

my $stringlike = to_ArrayRefOfStringlike($stringable);
ok(is_ArrayRefOfStringlike($stringlike), 'can coerce ArrayRefOfStringable to ArrayRefOfStringlike');
is_deeply($stringlike, [ './t', './xt' ], 'ArrayRefOfStringable properly coerced to ArrayRefOfStringlike');

done_testing;
