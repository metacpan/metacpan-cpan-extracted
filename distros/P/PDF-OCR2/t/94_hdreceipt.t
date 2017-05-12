use Test::Simple 'no_plan';
use lib './lib';
use PDF::OCR2;
use strict;

$PDF::OCR2::DEBUG = 1;
$PDF::OCR2::Page::DEBUG = 1;
$PDF::GetImages::DEBUG = 1;

my $p = PDF::OCR2->new('./t/leodocs/hdreceipt.pdf');
ok $p, 'instanced';
ok $p->text, 'text returns';

my $t = $p->text;

my $chars = length $t;
ok( $chars, "have $chars chars");









