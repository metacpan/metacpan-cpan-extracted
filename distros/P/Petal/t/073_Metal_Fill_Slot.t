#!/usr/bin/perl
use Test::More 'no_plan';
use warnings;
use lib 'lib';
use Petal;

$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::HTML_ERRORS  = 1;
$Petal::BASE_DIR     = ('t/data');

{
    my $file = 'metal-fill-slot.html';
    my $t = new Petal (file => $file);
    my $s = $t->process ( bar => 'myvar' );
    like ($s, qr/This is kind of a simple test/);
    like ($s, qr/myvar/);
}


1;
