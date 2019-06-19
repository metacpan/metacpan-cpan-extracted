#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

opendir( my $dir, 't/37-plan-without-costs/' );

my %uniq = ();
my @tests = sort { $a <=> $b }
    grep { !$uniq{ $_ }++ }
    map { s/\..*//; $_ }
    grep { /^\d+\.(?:expect|plan)$/ } readdir $dir;
closedir $dir;

plan 'tests' => 6 * scalar @tests;

for my $test ( @tests ) {
    my $expected = get_expected_from_file( $test );

    my $plan_file = 't/37-plan-without-costs/' . $test . '.plan';
    my $explain = Pg::Explain->new( 'source_file' => $plan_file );

    isa_ok( $explain,           'Pg::Explain',       "Parsed plan $test" );
    isa_ok( $explain->top_node, 'Pg::Explain::Node', "Parsed(2) plan $test" );
    cmp_deeply( $explain->top_node->get_struct(), $expected, "Got proper data from parse of plan $test" );

    my $reparsed = Pg::Explain->new( 'source' => $explain->as_text() );
    isa_ok( $reparsed,           'Pg::Explain',       "Reparsed plan $test" );
    isa_ok( $reparsed->top_node, 'Pg::Explain::Node', "Reparsed(2) plan $test" );
    cmp_deeply( $reparsed->top_node->get_struct(), $expected, "Got proper data from reparse of plan $test" );
}

exit;

sub get_expected_from_file {
    my $test_no = shift;

    my $filename = 't/37-plan-without-costs/' . $test_no . '.expect';

    open my $fh, '<', $filename;
    local $/ = undef;
    my $expected_str = <$fh>;
    close $fh;

    my $expected = eval $expected_str;
    die $@ if $@;

    return $expected;
}
