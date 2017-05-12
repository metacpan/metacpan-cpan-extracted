#!/usr/bin/perl

##
## Tests for Petal::Utils::Decode module
##

use blib;
use strict;

use Test::More qw(no_plan);
use Carp;

use t::LoadPetal;
use Petal::Utils qw( :logic :text );

my $str = "Flipper";
my $str2 = "Dipper";

my $template = Petal->new('25__decode.html');
my $out      = $template->process( {
    str => $str,
    str2 => $str2,
  } );

like($out, qr/decode1:\s*\n/, 'decode1');
like($out, qr/decode2:\s*\n/, 'decode2');
like($out, qr/decode2a: Flipper\n/, 'decode2a');
like($out, qr/decode2b: Flip\n/, 'decode2b');

like($out, qr/decode3: true\n/, 'decode3 - true (1)');
like($out, qr/decode4:\s*\n/, 'decode4 - false (0)');
like($out, qr/decode5:\ false_string\n/, 'decode5 - false (false)');
like($out, qr/decode6: Metal\n/, 'decode6');
like($out, qr/decode7:\s*\n/, 'decode7');
like($out, qr/decode8: true\n/, 'decode8');

like($out, qr/decode9: true\n/, 'decode9');
like($out, qr/decode10: 100\n/, 'decode10');
like($out, qr/decode11: 250\n/, 'decode11');


like($out, qr/decode12:\s\n/, 'decode12');
like($out, qr/decode13: true\n/, 'decode13');

like($out, qr/decode14: 1.\n/, 'decode14');
like($out, qr/decode15: .1\n/, 'decode15');


