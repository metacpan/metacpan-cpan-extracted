#!/usr/bin/perl
use Test::More 'no_plan';
use warnings;
use lib 'lib';
use Petal;

$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::HTML_ERRORS  = 1;
$Petal::BASE_DIR     = ('t/data/html_errors');
my $file             = 'not_xml.html';


{
    my $t = new Petal ( file => $file );
    my $s = $t->process();
    like ($s, qr/\<pre\>/);
    like ($s, qr/\<\/pre\>/);
}


$file = 'no_var.html';

{
    my $t = new Petal ( file => $file );
    my $s = $t->process();
    like ($s, qr/Cannot fetch/);
}
