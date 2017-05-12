#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;
use Petal::Parser::HTB;
$Petal::INPUT = 'HTML';

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;

my $string = Petal->new ( 'path_prefix.xml' )->process (foo => { baz => 'success' }, bar => 'baz');
like ($string, qr/success/);
