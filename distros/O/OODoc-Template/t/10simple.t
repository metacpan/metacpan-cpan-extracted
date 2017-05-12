#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib', '../lib', 't';
use Test::More tests => 66;

use Tools;

use OODoc::Template;

my $t = OODoc::Template->new;
ok(defined $t, 'create object');
isa_ok($t, 'OODoc::Template');

#
## plain
#

my $plain = "This has no tags.";

is(do_process($t, $plain), $plain, 'plain');

is(do_process($t, $plain, a => 42), $plain);

is(do_process($t, $plain, {a => 42}), $plain);

#
## variable
#

# var

my $var = "it is <!--{a}-->, you see";

is(do_process($t, $var), 'it is , you see', 'var');

is(do_process($t, $var, a => 42), 'it is 42, you see');

is(do_process($t, $var, {a => 42}), 'it is 42, you see');


# var2

my $var2 = "a=<!--{a}-->, b=<!--{b}--> , a=<!--{  
	   a
}-->, c = <!--{c}-->;";

is(do_process($t, $var2), 'a=, b= , a=, c = ;', 'var2 all empty');

is(do_process($t, $var2, a => 42), 'a=42, b= , a=42, c = ;');

is(do_process($t, $var2, {a => 42, b => 10, c => 6})
     , 'a=42, b=10 , a=42, c = 6;', 'var2 all used');

#
## Nesting
#

my $nest = <<__NEST;
X
<!--{a}-->Y
  b=<!--{b}-->
  c=<!--{c}-->
<!--{/a}-->Z
__NEST

is(do_process($t, $nest, a => [], b => 2), <<__N, 'nesting');
X
Z
__N

is(do_process($t, $nest, a => [{}], b => 2), <<__N);
X
Y
  b=2
  c=
Z
__N

#
## Repeat 
#

my $rep = <<__REP;
X
<!--{count}-->Y<!--{a}-->
<!--{/count}-->
__REP


is(do_process($t, $rep), <<__R, 'repeat');
X

__R

is(do_process($t, $rep, count => []), <<__R);
X

__R

is(do_process($t, $rep, count => [ {a => 3}, {a => 4}, {a => 7} ]), <<__R);
X
Y3
Y4
Y7

__R

is(do_process($t, $rep, count => [ {b => 9} ]), <<__R);
X
Y

__R

is(do_process($t, $rep, count => {a => 9}), <<__R);
X
Y9

__R
