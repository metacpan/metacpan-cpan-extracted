#!/usr/bin/perl
use Test::More 'no_plan';
use warnings;
use lib 'lib';
use Petal;

$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::BASE_DIR     = ('t/data/metal_double_include');
my $file             = 'main.xhtml';

{
    my $t = new Petal ( file => $file );
    my $s = $t->process();
    ok ($s !~ /include/);
}


$Petal::OUTPUT = 'XHTML';
{
    my $t = new Petal ( file => $file );
    my $s = $t->process();
    ok ($s !~ /include/);
}

