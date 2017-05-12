#!/usr/bin/perl

use strict;
use warnings;

use Test::More 1.001013;

use Path::Router;

my $r = Path::Router->new;
isa_ok($r, 'Path::Router');

$r->add_route('/math/simple/add', target => (bless {} => 'Math::Simple::add'));
$r->add_route('/math/simple/sub', target => (bless {} => 'Math::Simple::sub'));
$r->add_route('/math/simple/mul', target => (bless {} => 'Math::Simple::mul'));
$r->add_route('/math/simple/div', target => (bless {} => 'Math::Simple::div'));

isa_ok($r->match('math/simple/add')->target, 'Math::Simple::add');
isa_ok($r->match('math/simple/sub')->target, 'Math::Simple::sub');
isa_ok($r->match('math/simple/mul')->target, 'Math::Simple::mul');
isa_ok($r->match('math/simple/div')->target, 'Math::Simple::div');

done_testing;
