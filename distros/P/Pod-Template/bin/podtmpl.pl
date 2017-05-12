#!/usr/bin/perl -w
use strict;
use Pod::Template;
use Getopt::Long;
use Data::Dumper;
use FileHandle;

my $libs = [];
my $out;

GetOptions(
    "I=s" => $libs,
    "o=s" => \$out,
);

my $file    = shift or die usage();
my $parser  = Pod::Template->new( lib => [@$libs,@INC] );

$parser->parse( template => $file )
        or die qq[Failed to parse template '$file'\n];

my $fh;
if( $out ) {
    $fh = FileHandle->new( ">$out" )
            or die qq[Could not open '$out' for writing: $!\n];
    select $fh;                    
}

print $parser->as_string;

sub usage {
    return qq[
Usage:
    $0 [-I dir [-I dir]] [-o outfile] FILE    

$0 is a wrapper for the Pod::Template module.

It takes a Pod::Template enabled template and merges it with its
include files.  See 'perldoc Pod::Template' for details.

The result is printed to STDOUT by default, unless the '-o' option
is used (see below).

Options:
    -I  Include this directory in the search for templates and 
        other sources.  Can be specified multiple times.
    -o  File to print the result to.

    \n]           
}    
