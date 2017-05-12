#!/usr/bin/perl

$|=1;

use lib '../lib';

use strict;
use warnings;

use Time::HiRes qw( usleep  );

use String::ProgressBar;

my @bars = qw( first second third );


foreach my $bar (@bars){

    my $pr = String::ProgressBar->new( max => 30, print_return=>1, text=>$bar );

    foreach my $i (0..30){
        $pr->update( $i );  
        $pr->write;
        
        usleep ( 50000 );
    }
}



1;
