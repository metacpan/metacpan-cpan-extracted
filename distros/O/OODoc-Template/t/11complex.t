#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib', '../lib', 't';
use Test::More tests => 30;

use Tools;

use OODoc::Template;

my $t = OODoc::Template->new;
ok(defined $t, 'create object');
isa_ok($t, 'OODoc::Template');

my $templ = <<'__TEMPL';
A\
<!--{a}-->\
B\
   <!--{a}-->\
C\
<!--{/a}-->\
D\
__TEMPL

is(do_process($t, $templ), 'AD');

is(do_process($t, $templ, a => 42), 'AB42CD');

is(do_process($t, $templ, a => 0), 'AB0CD');

is(do_process($t, $templ, a => undef), 'AD');

is(do_process($t, $templ, a => ""), 'ABCD');


my $templ2 = <<'__TEMPL';
A\
<!--{a c=3}-->\
<!--{a}-->\
B\
<!--{c}-->\
<!--{/a}-->\
C\
<!--{c}-->\
<!--{a}-->\
<!--{a}-->\
D\
<!--{c}-->\
<!--{/a}-->\
E\
__TEMPL

is(do_process($t, $templ2), 'ACE');

is(do_process($t, $templ2, a => 42), 'A42B3C42DE');
