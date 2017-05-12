#!/usr/bin/perl

use strict;
use 5.005;
use Cwd;
use Test::More tests => 6;

BEGIN { use_ok 'Palm::Progect' }
require 't/utility.pl';

# Note that this is edge testing rather than unit testing.
# We are testing the functionality of the module as a whole.

# Here we load in a text file and check the following
# transformations:
#     * convert sample.txt to pdb.
#     * convert pdb to text.  Should be identical to sample.txt

my $perl        = $^X;
my $progconv    = 'bin/progconv';
my $infile_txt  = 't/infile.txt';
my $outfile_pdb = 't/outfile_18.pdb';
my $outfile_txt = 't/outfile.txt';
my $infile_pdb  = 't/sample_18.pdb';

write_sample_txt($infile_txt);

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--use-spaces', '--tabstop=4',
    '--date-format=dd/mm/yyyy',
    $infile_pdb, $outfile_txt
), 'executed progconv (1)');

ok(compare_text_files($infile_txt, $outfile_txt), 'pdb import');

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--use-spaces', '--tabstop=4',
    '--output-version=18',
    '--date-format=dd/mm/yyyy',
    $infile_txt, $outfile_pdb
), 'executed progconv (2)');

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--use-spaces', '--tabstop=4',
    '--date-format=dd/mm/yyyy',
    $outfile_pdb, $outfile_txt
), 'executed progconv (3)');

ok(compare_text_files($infile_txt, $outfile_txt), 'pdb import/export');

