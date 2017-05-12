#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = './t/data';

my $template;
my $string;



#####


{
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('hypen.xml');
    
    $string = $template->process(); 
    like ($string => qr/<foo-bar/);
    like ($string => qr/<\/foo-bar/);
}


__END__
