#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR = './t/data/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
my $template = new Petal ('dollar-one.xml');
my $string   = $template->process;

like ($string, qr|<a>\$</a>|);
like ($string, qr|<b>\$\$</b>|);
like ($string, qr|<c>\$_</c>|);

like ($string, qr|<d></d>|);
like ($string, qr|<e></e>|);

like ($string, qr|<f>\$@</f>|);
like ($string, qr|<g>\$1</g>|);
