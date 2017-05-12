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
    my $file = 'metal-define-slot.html';
    my $t = new Petal (file => $file);
    my $s = $t->process();
    like ($s, qr/Test/ => 'nuthin\'');
}


{
    my $file = 'metal-define-slot.html#testmacro';
    my $t = new Petal (file => $file);
    my $s = $t->process();
    unlike ($s, qr/html/ => 'testmacro');
}

{
    my $file = 'metal-define-slot.html#__metal_slot__boo';
    my $t = new Petal (file => $file);
    my $s = $t->process();
    like ($s, qr/Test Replace/ => 'fill-slot boo');
}

{
    my $file = 'metal-define-slot.html#testmacro';
    my $t = new Petal (file => $file);
    my $s = $t->process (__included_from__ => '/metal-define-slot.html');
    like ($s, qr/Test Replace/ => 'fill-slot boo');
}


1;
