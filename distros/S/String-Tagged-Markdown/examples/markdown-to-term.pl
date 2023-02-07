#!/usr/bin/perl

use v5.36;

use String::Tagged::Markdown;
use String::Tagged::Terminal;

use Getopt::Long;

GetOptions(
   'class|c=s' => \(my $CLASS = "String::Tagged::Markdown"),
) or exit 1;

require "$CLASS.pm" =~ s{::}{/}gr;

while( <STDIN> ) {
   chomp;
   String::Tagged::Terminal->new_from_formatting(
      $CLASS->parse_markdown( $_ )
         ->as_formatting
   )->say_to_terminal;
}
