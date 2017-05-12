#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::DECODE_CHARSET = 'UTF-8';
$Petal::ENCODE_CHARSET = 'UTF-8';
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;
$Petal::INPUT        = 'XHTML';
$Petal::OUTPUT       = 'XHTML';

ok (1);
if ($] > 5.007)
{
    my $string = Petal->new ( 'entities.html' )->process();
    my $copy   = chr (169);
    my $reg    = chr (174);
    my $nbsp   = chr (160);
    my $acirc  = chr (194);
    like ($string, qr/$copy/ => 'Copyright');
    like ($string, qr/$reg/ => 'Registered');
    like ($string, qr/$nbsp/ => 'Non-break space');
    unlike ($string, qr/$acirc/ => 'A circumflex not present');
}

