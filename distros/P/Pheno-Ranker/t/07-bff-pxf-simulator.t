#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec;
use JSON::XS;
use Test::More;
use File::Compare;
use lib qw(./lib ../lib t/lib);
use Test::PhenoRanker qw(fixture temp_output_file);

# Seed for srand
my $seed = 123456789;

# The command line script to be tested
my $script = File::Spec->catfile( 'utils', 'bff_pxf_simulator', 'bff-pxf-simulator' );
my @inc    = map { ( '-I', $_ ) } @INC;

##########
# TEST 1 #
##########

{
    # The reference file to compare the output with
    my $reference_file = fixture('individuals_random_100.json');

    # The generated output file
    my $tmp_file = temp_output_file();

    my $exit = system(
        $^X, @inc, $script,
        '-n',                            100,
        '-f',                            'bff',
        '-diseases',                     10,
        '-max-diseases-pool',            10,
        '-phenotypicFeatures',           10,
        '-max-phenotypicFeatures-pool',  10,
        '-treatments',                   10,
        '--max-treatments-pool',         10,
        '-procedures',                   10,
        '-max-procedures-pool',          10,
        '-exposures',                    10,
        '-max-exposures-pool',           10,
        '--random-seed',                 $seed,
        '-o',                            $tmp_file
    );
    is( $exit, 0, 'bff simulator exits cleanly for fixture test' );

    # Compare the output_file and the reference_file
  TODO: {
        local $TODO = 'exact seeded-random fixture differs on Windows'
          if $^O eq 'MSWin32';
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }
}

##########
# TEST 2 #
##########

{
    # The reference file to compare the output with
    my $reference_file = fixture('pxf_random_100.json');

    # The generated output file
    my $tmp_file = temp_output_file();

    my $exit = system(
        $^X, @inc, $script,
        '-n',                            100,
        '-f',                            'pxf',
        '-diseases',                     10,
        '-max-diseases-pool',            10,
        '-phenotypicFeatures',           10,
        '-max-phenotypicFeatures-pool',  10,
        '-treatments',                   10,
        '--max-treatments-pool',         10,
        '-procedures',                   10,
        '-max-procedures-pool',          10,
        '--random-seed',                 $seed,
        '-o',                            $tmp_file
    );
    is( $exit, 0, 'pxf simulator exits cleanly for fixture test' );

    # Compare the output_file and the reference_file
  TODO: {
        local $TODO = 'exact seeded-random fixture differs on Windows'
          if $^O eq 'MSWin32';
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }
}


##########
# TEST 3 #
##########

{
    # The reference file to compare the output with
    my $reference_file =
      fixture('individuals_random_100_ontologies.json');
    my $ont_file = fixture('ontologies.yaml');

    # The generated output file
    my $tmp_file = temp_output_file();

    my $exit = system(
        $^X, @inc, $script,
        '-n',                            100,
        '-f',                            'bff',
        '--external-ontologies',         $ont_file,
        '-diseases',                     1,
        '-max-diseases-pool',            1,
        '-phenotypicFeatures',           1,
        '-max-phenotypicFeatures-pool',  1,
        '-treatments',                   1,
        '-max-treatments-pool',          1,
        '--exposures',                   0,
        '-procedures',                   0,
        '--random-seed',                 $seed,
        '-o',                            $tmp_file
    );
    is( $exit, 0, 'bff simulator exits cleanly for external ontology fixture test' );

    ########
    # TODO #
    ########
    # Test 3 usually passes on most CPAN systems tested (90%), but it fails on a few (10% - incl. G. Colab).
    # Unlike tests 1 and 2, Test 3 uses the ontologies.yaml file.
    #
    # The problem seems to be with the rand() function, which generates inconsistent random
    # numbers. This leads to variations in certain fields (like sex, ethnicity) within the
    # ontologies. The exact cause of the failure is still unclear.
    # Note that srand/rand work fine when isolated.

  TODO: {
        local $TODO = 'failures due srand/rand system differences';

        # Compare the output_file and the reference_file
        ok(
            compare( $tmp_file, $reference_file ) == 0,
            qq/Output matches the <$reference_file> file/
        );
    }
}

######################
# STRUCTURAL TESTING #
######################

{
    my $tmp_file = temp_output_file();
    my $exit     = system(
        $^X, @inc, $script,
        '-n',                            3,
        '-f',                            'bff',
        '--diseases',                    2,
        '--max-diseases-pool',           4,
        '--phenotypicFeatures',          3,
        '--max-phenotypicFeatures-pool', 5,
        '--treatments',                  1,
        '--max-treatments-pool',         3,
        '--procedures',                  0,
        '--exposures',                   0,
        '--random-seed',                 $seed,
        '-o',                            $tmp_file
    );
    is( $exit, 0, 'bff simulator exits cleanly for structural test' );

    my $data = decode_json_file($tmp_file);
    is( scalar @{$data}, 3, 'bff simulator writes requested number of individuals' );
    is( $data->[0]{id}, 'Beacon_1', 'bff individual id is deterministic' );
    is( scalar @{ $data->[0]{diseases} }, 2, 'bff disease count matches requested count' );
    is( scalar @{ $data->[0]{phenotypicFeatures} }, 3, 'bff phenotypic feature count matches requested count' );
    is( scalar @{ $data->[0]{treatments} }, 1, 'bff treatment count matches requested count' );
    is( scalar @{ $data->[0]{interventionsOrProcedures} }, 0, 'bff procedures can be disabled' );
    is( scalar @{ $data->[0]{exposures} }, 0, 'bff exposures can be disabled' );
}

{
    my $tmp_file = temp_output_file();
    my $exit     = system(
        $^X, @inc, $script,
        '-n',                            2,
        '-f',                            'pxf',
        '--diseases',                    1,
        '--phenotypicFeatures',          2,
        '--max-phenotypicFeatures-pool', 4,
        '--treatments',                  1,
        '--procedures',                  1,
        '--exposures',                   0,
        '--random-seed',                 $seed,
        '-o',                            $tmp_file
    );
    is( $exit, 0, 'pxf simulator exits cleanly for structural test' );

    my $data = decode_json_file($tmp_file);
    is( scalar @{$data}, 2, 'pxf simulator writes requested number of phenopackets' );
    is( $data->[0]{id}, 'Phenopacket_1', 'pxf phenopacket id is deterministic' );
    is( scalar @{ $data->[0]{phenotypicFeatures} }, 2, 'pxf phenotypic feature count matches requested count' );
    is( scalar @{ $data->[0]{medicalActions} }, 2, 'pxf medical actions combine treatment and procedure entries' );
    is( scalar @{ $data->[0]{interpretations} }, 1, 'pxf interpretation count follows disease count' );
    like(
        $data->[0]{interpretations}[0]{progressStatus},
        qr/\A(?:SOLVED|UNSOLVED)\z/,
        'pxf interpretations include SOLVED or UNSOLVED progressStatus'
    );
    is(
        $data->[0]{interpretations}[0]{diagnosis}{disease}{id},
        $data->[0]{diseases}[0]{term}{id},
        'pxf interpretation diagnosis reuses the simulated disease term'
    );
    is(
        $data->[0]{interpretations}[0]{diagnosis}{genomicInterpretations}[0]{subjectOrBiosampleId},
        $data->[0]{subject}{id},
        'pxf genomic interpretation references the enclosing subject'
    );
}

######################
# VALIDATION TESTING #
######################

for my $case (
    [ 'invalid format',          [ '-f', 'foo' ] ],
    [ 'zero individuals',        [ '-n', 0 ] ],
    [ 'negative term count',     [ '--diseases', -1 ] ],
    [ 'zero max pool',           [ '--max-diseases-pool', 0 ] ],
    [ 'missing external YAML',   [ '--external-ontologies', 't/data/missing.yaml' ] ],
    [ 'term count exceeds pool', [ '--diseases', 2, '--max-diseases-pool', 1 ] ],
) {
    my ( $name, $args ) = @{$case};
    my $tmp_file = temp_output_file();
    my $exit = run_quietly( $^X, @inc, $script, @{$args}, '-o', $tmp_file );
    isnt( $exit, 0, "$name is rejected" );
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

sub decode_json_file {
    my $file = shift;
    open my $fh, '<:encoding(UTF-8)', $file;
    local $/;
    return JSON::XS->new->decode(<$fh>);
}

done_testing();
