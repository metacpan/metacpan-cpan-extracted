#!/usr/bin/perl
use Test::More 'no_plan';
use warnings;
use lib 'lib';
use Petal;

$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::BASE_DIR     = ('t/data');
my $file             = 'metal_self_include.xml';

{
    my $t = new Petal ( file => $file );
    my $s = $t->process();
    unlike ($s, qr/glop/);
}

$Petal::OUTPUT = 'XHTML';
{
    my $t = new Petal ( file => $file );
    my $s = $t->process();
    unlike ($s, qr/glop/);
}

