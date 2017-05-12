#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

BEGIN {
    use_ok('MooseX::Param');
}

{
    package My::Request;
    use Moose;
    
    with 'MooseX::Param';
    
    sub init_params {
        +{ hello => 'world' }
    }
}

my $r = My::Request->new;
isa_ok($r, 'My::Request');

ok($r->does('MooseX::Param'), '... this does the MooseX::Param role');

is_deeply(
{ hello => 'world' },
$r->params,
'... some params yet');

is_deeply(
[ 'hello' ],
[ $r->param ],
'... some param keys');

ok(defined($r->param('hello')), '... have hello param');
ok(!defined($r->param('foo')), '... no foo param');

lives_ok {
    $r->param(foo => 10);
} '... set the foo param ok';

is_deeply(
{ foo => 10, hello => 'world' },
$r->params,
'... one param now');

is_deeply(
[ sort 'foo', 'hello' ],
[ sort $r->param ],
'... one param key');

is($r->param('foo'), 10, '... we have a foo param');

lives_ok {
    $r->param(bar => 20, baz => 30);
} '... set the bar and baz param ok';

is_deeply(
{ foo => 10, bar => 20, baz => 30, hello => 'world' },
$r->params,
'... many params now');

is_deeply(
[ sort 'bar', 'baz', 'foo', 'hello' ],
[ sort $r->param ],
'... 3 param keys');

is($r->param('foo'), 10, '... we have a foo param (still)');
is($r->param('bar'), 20, '... we have a bar param');
is($r->param('baz'), 30, '... we have a baz param');

lives_ok {
    $r->param(foo => undef);
} '... unset the foo param ok';

ok(!defined($r->param('foo')), '... no more foo param');



