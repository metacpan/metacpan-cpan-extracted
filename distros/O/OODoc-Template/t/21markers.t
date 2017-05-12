#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib', '../lib', 't';
use Test::More tests => 18;

use OODoc::Template;
use Tools;

my @data = (a => [ {b=>42}, {b=>43}] );

my $t = OODoc::Template->new(markers => [ '<{', '}>' ], @data);

ok(defined $t, 'create object t');
isa_ok($t, 'OODoc::Template');

is(do_process($t, "<{a}><{b}><{/a}>"), '4243');


my $t2 = OODoc::Template->new(markers => [ '<{', '}>', '<[', ']>' ], @data);
ok(defined $t2, 'create object t2');
isa_ok($t2, 'OODoc::Template');

is(do_process($t2, "<{a}><{b}><[a]>"), '4243');


my $t3 = OODoc::Template->new;
ok(defined $t3, 'create object t3');
isa_ok($t3, 'OODoc::Template');
is(do_process($t3, <<'__TEST', c=>10), <<'__SHOW');
<!--{define markers => "<{,}>" }-->\
    value of c: <{c}>\
<!--{/define}-->
__TEST
    value of c: 10
__SHOW

