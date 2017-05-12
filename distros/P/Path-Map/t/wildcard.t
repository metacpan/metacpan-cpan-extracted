use strict;
use warnings;

use Test::More tests => 12;

use Path::Map;

my $mapper = Path::Map->new( 'foo/:foo/*/blah' => 'ABC' );

my $match = $mapper->lookup('foo/bar/baz/qux');
is $match->handler, 'ABC';
is_deeply(
    $match->variables,
    { foo => 'bar' },
);
is_deeply(
    $match->values,
    [qw( bar baz qux )],
);

# Check conflicting paths, plus a catch-all
$mapper = Path::Map->new(
    'foo/*'        => 'Wild',
    'foo/:foo/bar' => 'Specific',
    '*'            => 'Default',
);

$match = $mapper->lookup('foo/foo/foo');
is $match->handler, 'Wild';
is_deeply $match->variables, {};
is_deeply $match->values, [qw( foo foo )];

$match = $mapper->lookup('foo/foo/bar');
is $match->handler, 'Specific';
is_deeply $match->variables, { foo => 'foo' };
is_deeply $match->values, [qw( foo )];

$match = $mapper->lookup('bar');
is $match->handler, 'Default';
is_deeply $match->variables, {};
is_deeply $match->values, [qw( bar )];
