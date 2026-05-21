#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec;
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Test::More;
use lib qw(./lib ../lib t/lib);
use Test::PhenoRanker qw(fixture);
use Pheno::Ranker::IO qw(read_json read_yaml);

# The command line script to be tested
my $script = catfile( 'utils', 'csv2pheno_ranker', 'csv2pheno-ranker' );
my @inc = map { ( '-I', $_ ) } @INC;

############
# TEST 1-2 #
############

{
    # Input file for the command line script, if needed
    my $input_file = fixture('example.csv');

    # The reference files to compare the output with
    my $reference_file   = fixture('example_ref.json');
    my $reference_config = fixture('example_config_ref.yaml');

    # The exppected output files from csv2pheno-ranker 
    my $output_dir = tempdir( CLEANUP => 1 );
    my $file       = catfile( $output_dir, 'example.json' );
    my $config     = catfile( $output_dir, 'example_config.yaml' );

    my $exit = system(
        $^X, @inc, $script,
        '-i',                 $input_file,
        '--output-dir',       $output_dir,
        '-sep',               ';',
        '--generate-primary-key',
        '--primary-key-name', 'Id',
        '--array-separator',  ','
    );
    is( $exit, 0, 'csv2pheno-ranker exits cleanly' );
    ok( -e $file,   "csv2pheno-ranker created <$file>" );
    ok( -e $config, "csv2pheno-ranker created <$config>" );

    is_deeply(
        read_json($file),
        read_json($reference_file),
        qq/Output matches the <$reference_file> file/
    );
    is_deeply(
        read_yaml($config),
        read_yaml($reference_config),
        qq/Output matches the <$reference_config> file/
    );
}

######################
# VALIDATION TESTING #
######################

{
    my $output_dir = tempdir( CLEANUP => 1 );
    my $input_file = catfile( $output_dir, 'duplicate.csv' );
    write_file( $input_file, "id,(id)\nA,B\n" );

    my $exit = run_quietly( $^X, @inc, $script, '-i', $input_file );
    isnt( $exit, 0, 'duplicate headers after normalization are rejected' );
}

{
    my $output_dir = tempdir( CLEANUP => 1 );
    my $input_file = catfile( $output_dir, 'empty_header.csv' );
    write_file( $input_file, "()\nA\n" );

    my $exit = run_quietly( $^X, @inc, $script, '-i', $input_file );
    isnt( $exit, 0, 'empty headers after normalization are rejected' );
}

{
    my $input_file = fixture('example.csv');
    my $exit = run_quietly( $^X, @inc, $script, '-i', $input_file, '--separator', '::' );
    isnt( $exit, 0, 'multi-character field separators are rejected' );
}

{
    my $input_file = fixture('example.csv');
    my $exit =
      run_quietly( $^X, @inc, $script, '-i', $input_file, '--array-separator', '[' );
    isnt( $exit, 0, 'invalid array separator regular expressions are rejected' );
}

sub write_file {
    my ( $file, $content ) = @_;
    open my $fh, '>:encoding(UTF-8)', $file;
    print {$fh} $content;
    close $fh;
    return 1;
}

sub run_quietly {
    open my $old_stdin, '<&', \*STDIN
      or die 'Cannot duplicate STDIN: ' . $!;
    open my $old_stdout, '>&', \*STDOUT
      or die 'Cannot duplicate STDOUT: ' . $!;
    open my $old_stderr, '>&', \*STDERR
      or die 'Cannot duplicate STDERR: ' . $!;

    open STDIN, '<', File::Spec->devnull
      or die 'Cannot redirect STDIN to null device: ' . $!;
    open STDOUT, '>', File::Spec->devnull
      or die 'Cannot redirect STDOUT to null device: ' . $!;
    open STDERR, '>', File::Spec->devnull
      or die 'Cannot redirect STDERR to null device: ' . $!;

    my $exit = system(@_);

    open STDIN, '<&', $old_stdin
      or die 'Cannot restore STDIN: ' . $!;
    open STDOUT, '>&', $old_stdout
      or die 'Cannot restore STDOUT: ' . $!;
    open STDERR, '>&', $old_stderr
      or die 'Cannot restore STDERR: ' . $!;

    return $exit;
}

done_testing();
