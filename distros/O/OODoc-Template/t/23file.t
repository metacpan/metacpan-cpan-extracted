#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib', '../lib', 't';
use Test::More tests => 14;

use OODoc::Template;
use Tools;

my $t = OODoc::Template->new(search => 't:.');
ok(defined $t, 'create object t');
isa_ok($t, 'OODoc::Template');

is(do_process($t, <<'__TEST'), <<'__SHOW');
<!--{define a => 'monkey'}-->\
   <!--{template file => 'nl/demo.tpl'}-->\
<!--{/define}-->
<!--{template file=nl/demo.tpl, a => 'donkey'}-->
<!--{template file => 'nl/demo.tpl'}-->
__TEST
This is the demo template
Fill in: monkey

This is the demo template
Fill in: donkey

This is the demo template
Fill in: 

__SHOW

is(do_process($t, <<'__TEST', lang => 'nl'), <<'__SHOW');
<!--{template file => "$lang/demo.tpl", a => dutch}-->\
__TEST
This is the demo template
Fill in: dutch
__SHOW

is(do_process($t, <<'__TEST', lang => 'nl'), <<'__SHOW');
<!--{template file=missing alt=$lang/demo.tpl a=french}-->\
__TEST
This is the demo template
Fill in: french
__SHOW
