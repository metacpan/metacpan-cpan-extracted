#!perl

use Test::More;
use Test::Deep;
use Data::Dumper;
use autodie;

use Pg::Explain;

my @tests = @ARGV;
if (0 == scalar @tests) {
    opendir( my $dir, 't/17-as_text' );

    my %uniq = ();
    @tests = sort { $a <=> $b }
        grep { !$uniq{ $_ }++ }
        map { s/-.*//; $_ }
        grep { /^\d+-plan$/ } readdir $dir;

    closedir $dir;
}

plan 'tests' => 5 * scalar @tests;

for my $test ( @tests ) {

    print STDERR 'Working on test ' . $test . "\n" if  $ENV{'DEBUG_TESTS'};

    my $plan_file = 't/17-as_text/' . $test . '-plan';

    my $explain = Pg::Explain->new( 'source_file' => $plan_file );
    isa_ok( $explain, 'Pg::Explain' );
    isa_ok( $explain->top_node, 'Pg::Explain::Node' );

    my $textual = $explain->as_text();

    my $reparsed = Pg::Explain->new( 'source' => $textual );
    isa_ok( $reparsed, 'Pg::Explain' );
    isa_ok( $reparsed->top_node, 'Pg::Explain::Node' );

    my $expected = $explain->top_node->get_struct();
    my $got = $reparsed->top_node->get_struct();

    print STDERR Dumper($got) if  $ENV{'DEBUG_TESTS'};

    cmp_deeply( $got, $expected, 'Plan no. ' . $test . ' passed as file.', );
}

exit;
