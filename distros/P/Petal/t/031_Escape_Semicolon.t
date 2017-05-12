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
    $Petal::OUTPUT = "XML";
    $template = new Petal ('test_attributes2.xml');
    
    $string = $template->process(); 
    unlike($string, '/\\\\;/');
}


{
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('test_attributes2.xml');

    $string = $template->process(); 
    unlike($string, '/\\\\;/');
}


__END__
