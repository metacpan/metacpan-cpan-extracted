#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib', '../lib', 't';
use Test::More tests => 6;

use OODoc::Template;
use Tools;

my $t = OODoc::Template->new;
ok(defined $t, 'create object t');
isa_ok($t, 'OODoc::Template');

is(do_process($t, <<'__TEST'), <<'__SHOW');
<!--{macro name => try}-->\
try this <!--{this}-->\
<!--{/macro}-->\

<!--{template macro => try, this => 'one'}-->
<!--{template macro => try, this => 'two'}-->
__TEST
try this one
try this two
__SHOW
