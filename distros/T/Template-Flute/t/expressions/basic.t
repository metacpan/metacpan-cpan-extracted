# Basic tests for expressions

use strict;
use warnings;

use Test::More tests => 16;
use Test::Warnings;

use Template::Flute::Expression;

my ($expr, $ret, $result);

# value test
$expr = Template::Flute::Expression->new('value');

$ret = $expr->evaluate({value => 1});
ok($ret, 'Test value with value 1')
    || diag "Result: $result.";

$ret = $expr->evaluate({value => 0});
ok(!$ret, 'Test value with value 0')
    || diag "Result: $result.";

$ret = $expr->evaluate({});
ok(! $ret, 'Test value without value')
    || diag "Result: $result.";

# !value test
$expr = Template::Flute::Expression->new('!value');

$ret = $expr->evaluate({value => 1});
ok(! $ret, 'Test !value with value 1')
    || diag "Result: $result.";

$ret = $expr->evaluate({value => 0});
ok($ret, 'Test !value with value 0')
    || diag "Result: $result.";

$ret = $expr->evaluate({});
ok($ret, 'Test !value without value')
    || diag "Result: $result.";

# session.value test
$expr = Template::Flute::Expression->new('session.value');

$ret = $expr->evaluate({session => {value => 1}});
ok($ret, 'Test session.value with value 1')
    || diag "Result: $result.";

$ret = $expr->evaluate({session => {value => 0}});
ok(! $ret, 'Test session.value with value 0')
    || diag "Result: $result.";

$ret = $expr->evaluate({});
ok(! $ret, 'Test session.value without value')
    || diag "Result: $result.";

# !session.value test
$expr = Template::Flute::Expression->new('!session.value');

$ret = $expr->evaluate({session => {value => 1}});
ok(! $ret, 'Test !session.value with value 1')
    || diag "Result: $result.";

$ret = $expr->evaluate({session => {value => 0}});
ok($ret, 'Test !session.value with value 0')
    || diag "Result: $result.";

$ret = $expr->evaluate({});
ok($ret, 'Test !session.value without value')
    || diag "Result: $result.";

# session.value.message test
$expr = Template::Flute::Expression->new('session.value.message');

$ret = $expr->evaluate({session => {value => {message => 1}}});
ok($ret, 'Test session.value.message with value 1')
    || diag "Result: $result.";

$ret = $expr->evaluate({session => {value => 0}});
ok(! $ret, 'Test session.value.message with value 0')
    || diag "Result: $result.";

$ret = $expr->evaluate({});
ok(! $ret, 'Test session.value.message without value')
    || diag "Result: $result.";
