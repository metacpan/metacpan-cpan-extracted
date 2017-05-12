#!/usr/bin/perl -l

use strict;
use Getopt::Std;
use Fatal qw( open );
use Parse::Flex::Generate;

my $dir='del/';
#$SIG { INT } =  sub{ $dir =~ m'\w/$' and system "rm -rf $dir" } ;


my %opt;
getopts 'vhkl:n:', \%opt;

### Defaults and Error Checking
my $flex_flags = '-Cf';
my $Grammar = shift (@ARGV) || 'grammar.l';
my $Pack    = $opt{n}       || "Flexer$$" ; 

$opt{h} and Usage( $Pack ) and exit;
$opt{l} or $opt{l} = $flex_flags ;
check_argv ( $Pack, $Grammar);

## Initializations
my  $pm  = pm_content $Pack       ;
my  $mk  = makefile_content $Pack, $Grammar, $opt{l}, $opt{v} ;
my  $xs  = xs_content( $Pack )    ;

## setup for compilation
$dir and system qq( mkdir -p $dir);
$dir and system qq( cp  $Grammar $dir );
open OUT , "> $dir${Pack}.xs" ; print OUT $xs; close OUT;
open OUT , "> $dir${Pack}.pm" ; print OUT $pm; close OUT;
open OUT , "> ${dir}Makefile" ; print OUT $mk; close OUT;

## Compile
open OUT , "| make n=1 -sC $dir -f - "  ; 
print OUT $mk; close OUT;
$dir =~ m'\w/$' and system "rm -rf $dir"   unless $opt{k} ;

