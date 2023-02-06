#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged::Terminal;

my $st = String::Tagged::Terminal->new
   ->append_tagged( "a string with " )
   ->append_tagged( "bold", bold => 1 )
   ->append_tagged( " formatting" );

{
   open my $fh, ">", \my $output;

   $st->print_to_terminal( $fh );

   is( $output, "a string with \e[1mbold\e[m formatting",
      'printed correct output' );
}

{
   open my $fh, ">", \my $output;

   $st->say_to_terminal( $fh );

   like( $output, qr/a string with \e\[1mbold\e\[m formatting\r?\n/,
      'output includes linefeed' );
}

done_testing;
