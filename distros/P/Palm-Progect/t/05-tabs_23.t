#!/usr/bin/perl -w

use strict;
use 5.005;
use Cwd;

use Test::More tests => 13;

BEGIN { use_ok 'Palm::Progect' }
require 't/utility.pl';

# Note that this is edge testing rather than unit testing.
# We are testing the functionality of the module as a whole.

# Here we load in a text file and check the following
# transformations:
#     * convert sample.txt to text.  Should be identical

my $perl                  = $^X;
my $progconv              = 'bin/progconv';
my $infile_txt            = 't/infile.txt';
my $infile_txt_with_tabs  = 't/infilet.txt';
my $outfile_txt           = 't/outfile.txt';
my $file_pdb              = 't/outfile_23.pdb';
my $outfile_txt_with_tabs = 't/outfilet.txt';

write_sample_txt($infile_txt);
write_sample_txt_with_tabs($infile_txt_with_tabs);

# text => pdb => text/tabs => pdb => text

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--use-spaces', '--tabstop=4',
    '--date-format=dd/mm/yyyy',
    '--output-version=23',
    $infile_txt, $file_pdb
), 'progconv - text to pdb');

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--date-format=dd/mm/yyyy',
    $file_pdb, $outfile_txt_with_tabs
), 'progconv - pdb to text (w. tabs)');

ok(compare_text_files($infile_txt_with_tabs, $outfile_txt_with_tabs), 'text (w. tabs) matches text (w. tabs)');

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--date-format=dd/mm/yyyy',
    '--output-version=23',
    $outfile_txt_with_tabs, $file_pdb
), 'progconv - text (w. tabs) to pdb');

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--date-format=dd/mm/yyyy',
    '--use-spaces', '--tabstop=4',
    $file_pdb, $outfile_txt
), 'progconv - pdb to text');

ok(compare_text_files($infile_txt, $outfile_txt), 'text matches text');

# text/tabs => pdb => text => pdb => text/tabs

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--date-format=dd/mm/yyyy',
    '--output-version=23',
    $infile_txt_with_tabs, $file_pdb
), 'text (w.tabs) to pdb');

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--date-format=dd/mm/yyyy',
    '--use-spaces', '--tabstop=4',
    $file_pdb, $outfile_txt
), 'progconv - pdb to text');

ok(compare_text_files($infile_txt, $outfile_txt), 'text matches text');

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--date-format=dd/mm/yyyy',
    '--use-spaces', '--tabstop=4',
    '--output-version=23',
    $outfile_txt, $file_pdb
), 'progconv - text to pdb');

ok(!system(
    $perl, $progconv,
    '--quiet',
    '--date-format=dd/mm/yyyy',
    $file_pdb, $outfile_txt_with_tabs
), 'progconv - pdb to text (w. tabs)');

ok(compare_text_files($infile_txt_with_tabs, $outfile_txt_with_tabs), 'text (w. tabs) matches text (w. tabs)');

