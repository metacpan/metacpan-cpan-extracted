#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib', '../lib', 't';
use Test::More tests => 66;

use OODoc::Template;
use Tools;

my $t = OODoc::Template->new();
ok(defined $t, 'create object');
isa_ok($t, 'OODoc::Template');

#
## true as array of hashes
#

is(do_process($t, <<'__TEST', true => [{}]), <<'__SHOW', 'true ARRAY of HASH');
<!--{true}-->yes<!--{/true}-->
__TEST
yes
__SHOW

is(do_process($t, <<'__TEST', true => [{}]), <<'__SHOW');
<!--{IF true}-->yes<!--{/true}-->
__TEST
yes
__SHOW

is(do_process($t, <<'__TEST', true => [{}]), <<'__SHOW');
<!--{NOT true}-->no<!--{/true}-->
__TEST

__SHOW

is(do_process($t, <<'__TEST', true => [{}]), <<'__SHOW');
<!--{true}-->yes<!--{ELSE true}-->no<!--{/true}-->
__TEST
yes
__SHOW

#
## true as single hash
#

is(do_process($t, <<'__TEST', true => {}), <<'__SHOW', 'true single HASH');
<!--{true}-->yes<!--{/true}-->
__TEST
yes
__SHOW

is(do_process($t, <<'__TEST', true => {}), <<'__SHOW');
<!--{NOT true}-->no<!--{/true}-->
__TEST

__SHOW

is(do_process($t, <<'__TEST', true => {}), <<'__SHOW');
<!--{true}-->yes<!--{ELSE true}-->no<!--{/true}-->
__TEST
yes
__SHOW

#
## false as empty array
#

is(do_process($t, <<'__TEST', false => []), <<'__SHOW', 'false empty ARRAY');
<!--{false}-->yes<!--{/false}-->
__TEST

__SHOW

is(do_process($t, <<'__TEST', false => []), <<'__SHOW');
<!--{NOT false}-->no<!--{/false}-->
__TEST
no
__SHOW

is(do_process($t, <<'__TEST', false => []), <<'__SHOW');
<!--{false}-->yes<!--{ELSE false}-->no<!--{/false}-->
__TEST
no
__SHOW

#
## false as undef
#

is(do_process($t, <<'__TEST', false => undef), <<'__SHOW', 'false via undef');
<!--{false}-->yes<!--{/false}-->
__TEST

__SHOW

is(do_process($t, <<'__TEST', false => undef), <<'__SHOW');
<!--{NOT false}-->no<!--{/false}-->
__TEST
no
__SHOW

is(do_process($t, <<'__TEST', false => undef), <<'__SHOW');
<!--{false}-->yes<!--{ELSE false}-->no<!--{/false}-->
__TEST
no
__SHOW

#
## false as undefined
#

is(do_process($t, <<'__TEST'), <<'__SHOW', 'false as non-existing');
<!--{false}-->yes<!--{/false}-->
__TEST

__SHOW

is(do_process($t, <<'__TEST'), <<'__SHOW');
<!--{NOT false}-->no<!--{/false}-->
__TEST
no
__SHOW

is(do_process($t, <<'__TEST'), <<'__SHOW');
<!--{false}-->yes<!--{ELSE false}-->no<!--{/false}-->
__TEST
no
__SHOW
