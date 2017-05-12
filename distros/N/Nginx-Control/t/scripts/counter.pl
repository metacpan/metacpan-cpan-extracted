#!/usr/bin/perl

use strict;
use warnings;

use FCGI::Engine;

{
    package Counter;
    use Moose;
    
    my $count = 0;
    
    sub handler { 
        print("Content-type: text/html\r\n\r\n");
        print(++$count);
    }
}

FCGI::Engine->new_with_options(handler_class => 'Counter')->run;