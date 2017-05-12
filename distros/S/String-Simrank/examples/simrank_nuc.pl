#!/usr/bin/env perl

# One can run this program directly from the directory above the 
# test_data directory within the distribution directory with this command:
# perl examples/simrank_nuc.pl --query test_data/query.fasta --data test_data/db.fasta
# System admins may want to modify and copy this file to /usr/local/bin so users can run it directly.

use strict;
use warnings FATAL => qw ( all );

use Getopt::Long;

use lib 'lib';
use String::Simrank;

my ( $prog_name, $cl_args, $usage, $signature );

$prog_name = ( split "/", $0 )[-1];
$signature = 'Niels Larsen';

$usage = qq (
Program $prog_name, May 2004, April 2002

This program quickly estimates the overall similarity between 
a given set of DNA or RNA sequence(s) and a background set of 
of homologues. It returns a sorted list of similarities as a 
table. The similarity between sequences A and B are the number
of unique k-words (short subsequence) that they share, divided
by the smallest total k-word count in either A or B. The result
are scores that do not depend on sequence lengths. The program,
when run for the first time, builds a binary file for efficieny.
Command line arguments are (brackets mean optional and D means
default value),

   --query path      ( Query sequence(s), fasta format )
    --data path      ( Database sequence(s), fasta format )
 
[ --wordlen int ]    ( D = 7; word length used )
 [ --minlen int ]    ( D = 50; minimum sequence length )
 [ --minpct flt ]    ( D = 50; minimum match percentage )
 [ --outlen int ]    ( D = 100; output length cutoff )
[ --outfile path ]    ( D = false; output file )

    [ --rebuild ]    ( D = off; force making new binary )
     [ --silent ]    ( D = off; progress screen messages )
    [ --reverse ]    ( D = off; complements input sequence(s) )
      [ --noids ]    ( D = off; print numbers instead of ids )

Author: $signature

);

print STDERR $usage and exit if not @ARGV;

# >>>>>>>>>>>>>>>>>>>>> GET ARGUMENTS <<<<<<<<<<<<<<<<<<<<<<<<<

if ( not &GetOptions (
                      "data=s" => \$cl_args->{"data"},
                      "query=s" => \$cl_args->{"query"},
                      "wordlen=s" => \$cl_args->{"wordlen"},
                      "minlen=s" => \$cl_args->{"minlen"},
                      "minpct=f" => \$cl_args->{"minpct"},
                      "outlen=s" => \$cl_args->{"outlen"},
                      "outfile=s" => \$cl_args->{"outfile"},
                      "rebuild!" => \$cl_args->{"rebuild"},
                      "silent!" => \$cl_args->{"silent"},
                      "reverse!" => \$cl_args->{"reverse"},
                      "noids" => \$cl_args->{"noids"},
                     ) )
{
    exit;
}

# >>>>>>>>>>>>>>>>>>>>>>>>>> MATCH <<<<<<<<<<<<<<<<<<<<<<<<<<<<


my $sr = new String::Simrank ({ data => $cl_args->{data} });
if ($cl_args->{"rebuild"} || !$sr->{binary_ready} ) {
    $sr->formatdb({ wordlen => $cl_args->{wordlen},
	        minlen  => $cl_args->{minlength},
	        silent  => $cl_args->{silent},
	     });
}
$sr->match_oligos( { query => $cl_args->{query},
                      outlen => $cl_args->{outlen},
                      minpct => $cl_args->{minpct},
                      reverse => $cl_args->{reverse},
		     outfile => $cl_args->{outfile},
		     noids   => $cl_args->{noids},
                     silent => $cl_args->{silent},
                    
                    });

print STDERR "$0 Done\n" if not $cl_args->{"silent"};

# >>>>>>>>>>>>>>>>>>>> END OF MAIN PROGRAM <<<<<<<<<<<<<<<<<<<<

__END__
