#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;
use Test::Exception;

BEGIN {
    use_ok('MooseX::Param');
}

{
    package My::Request;
    use Moose;
    
    with 'MooseX::Param';
    
}

my $r = My::Request->new;
isa_ok($r, 'My::Request');

ok($r->does('MooseX::Param'), '... this does the MooseX::Param role');

is_deeply(
{},
$r->params,
'... no params yet');

is_deeply(
[],
[ $r->param ],
'... no param keys');

ok(!defined($r->param('foo')), '... no foo param');

lives_ok {
    $r->param(foo => 10);
} '... set the foo param ok';

is_deeply(
{ foo => 10 },
$r->params,
'... one param now');

is_deeply(
[ 'foo' ],
[ $r->param ],
'... one param key');

is($r->param('foo'), 10, '... we have a foo param');

lives_ok {
    $r->param(bar => 20, baz => 30);
} '... set the bar and baz param ok';

is_deeply(
{ foo => 10, bar => 20, baz => 30 },
$r->params,
'... many params now');

is_deeply(
[ 'bar', 'baz', 'foo' ],
[ sort $r->param ],
'... 3 param keys');

is($r->param('foo'), 10, '... we have a foo param (still)');
is($r->param('bar'), 20, '... we have a bar param');
is($r->param('baz'), 30, '... we have a baz param');

lives_ok {
    $r->param(foo => undef);
} '... unset the foo param ok';

ok(!defined($r->param('foo')), '... no more foo param');



