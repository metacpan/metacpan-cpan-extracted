#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib', '../lib', 't';
use Test::More tests => 10;

use OODoc::Template;
use Tools;

my $t = OODoc::Template->new;
ok(defined $t, 'create object');
isa_ok($t, 'OODoc::Template');

my $ws1 = <<'__WS1';
a\
b   \
c\
   d\

\

e
   f

__WS1

is(do_process($t, $ws1), <<__WS1);
ab   c   de
   f

__WS1

my $ws2 = <<'__WS2';
A=\
   <!--{a}-->\
      <!--{b}-->\
         <!--{x}-->,\
         <!--{y}-->
      <!--{/b}-->\
   <!--{/a}-->\
Z
__WS2

my %ws2 = ( a => [ {x => 12},{x => 13} ], b => [ {y => 42} ] );
is(do_process($t, $ws2, \%ws2), <<__WS2);
A=12,42
      13,42
      Z
__WS2
