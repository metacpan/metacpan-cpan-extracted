#!/usr/bin/perl

use v5.36;

use String::Tagged::Markdown;
use String::Tagged::Terminal;

while( <STDIN> ) {
   chomp;
   String::Tagged::Terminal->new_from_formatting(
      String::Tagged::Markdown->parse_markdown( $_ )
         ->as_formatting
   )->say_to_terminal;
}
