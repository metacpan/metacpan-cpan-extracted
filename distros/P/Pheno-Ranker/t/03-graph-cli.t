#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec::Functions qw(catfile);
use Test::More tests => 6;        # Indicate the number of tests you want to run
use lib qw(./lib ../lib t/lib);
use Test::PhenoRanker qw(fixture temp_output_file);
use Pheno::Ranker::IO qw(read_json);

# The command line script to be tested
my $script = catfile( 'bin', 'pheno-ranker' );
my $inc    = join ' -I', '', @INC;    # prepend -I to each path in @INC

############
# TEST 1-2 #
############

{
    # Input file for the command line script, if needed
    my $input_file = fixture('individuals.json');

    # The generated output files
    my $tmp_file1 = temp_output_file();
    my $tmp_file2 = temp_output_file( suffix => '.txt' );

    # Run the command line script with the input file, and redirect the output to the output_file
    system(
"$^X $inc $script -r $input_file --cytoscape-json $tmp_file1 --graph-stats $tmp_file2"
    );

    my $graph = read_json($tmp_file1);
    is scalar @{ $graph->{elements}{nodes} }, 36,
      'CLI direct graph export writes all cohort nodes';
    is scalar @{ $graph->{elements}{edges} }, 630,
      'CLI direct graph export writes upper-triangle graph edges';

    like slurp($tmp_file2), qr/^Metric: Hamming/m,
      'CLI graph stats are generated from the direct graph';

}

{
    my $input_file = fixture('individuals.json');
    my $graph_file = temp_output_file( suffix => '.json' );
    my $mtx_file   = temp_output_file( suffix => '.mtx' );

    system(
"$^X $inc $script -r $input_file --matrix-format mtx -o $mtx_file --cytoscape-json $graph_file --graph-max-weight 10"
    );

    ok -f $mtx_file, 'CLI writes Matrix Market output with Cytoscape graph export';

    my $graph = read_json($graph_file);
    is scalar @{ $graph->{elements}{nodes} }, 36,
      'CLI mtx plus graph export writes all cohort nodes';
    my $too_heavy = grep { $_->{data}{weight} > 10 } @{ $graph->{elements}{edges} };
    ok !$too_heavy, 'CLI direct graph export applies max-weight filtering';
}

sub slurp {
    my $file = shift;
    open my $fh, '<:encoding(UTF-8)', $file;
    local $/;
    return <$fh>;
}
