
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

# makes sure parsing code used in testing works

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More tests => 8;

require_ok('ToyXML');
ToyXML->import('parse');

my $e;

$e = parse('<foo/>');
is( $e->tag, 'foo', 'parsed a simple, single-element tree' );

$e = parse('<foo></foo>');
is( $e->tag, 'foo', 'parsed a simple, two-element tree' );

$e = parse('<foo><bar/><baz><quux/></baz></foo>');
is( $e->tag, 'foo', 'parsed a tree with leaf and non-leaf nodes' );
is(
    $e->to_string,
    '<foo><bar/><baz><quux/></baz></foo>',
    'stringified complex tree correctly'
);

$e = parse('<foo bar="quux"/>');
ok( $e->has_attribute('bar'), 'parsed attribute' );
is( $e->attribute('bar'), 'quux', 'correct attribute value' );

$e = parse('<foo bar="quux"><baz><quux corge="a" grue="b"/></baz></foo>');
is( $e->child(0)->child(0)->attribute('grue'),
    'b', 'parsed attribute out of complex tree' );
