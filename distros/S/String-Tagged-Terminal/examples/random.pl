#!/usr/bin/perl

use v5.14;
use warnings;

use String::Tagged::Terminal;

my $st = String::Tagged::Terminal->new( "Random stuff: " );

foreach ( 1 .. 100 ) {
  my $str = chr( 0x41 + rand 26 ) x ( 5 + rand 5 );
  $st->append_tagged( $str, fgindex => 1 + rand 6 );
  $st->append( " " );
}

$st->say_to_terminal;
