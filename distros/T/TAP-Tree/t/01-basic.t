use strict;
use warnings;

use Test::More tests => 3;

my $tap = <<'END';
1..3
ok 1 - first test
    # Subtest: second test
    ok 1 - first sub test
        # Subtest: second sub test
        ok 1 - sub sub test
        1..1
    ok 2 - second sub test
        # Subtets: third sub test
        1..1
        ok 1 - sub sub sub test
    ok 3 - third sub test
    1..3
ok 2 - second test
ok 3 - third test
END

require TAP::Tree;
my $taptree = TAP::Tree->new( tap_ref => \$tap );
my $tree    = $taptree->parse;

subtest 'summary' => sub {
    plan tests => 9;

    my $summary = $taptree->summary;

    is( $summary->{planned_tests},  3, 'planned tests' );
    is( $summary->{ran_tests},      3, 'ran tests' );
    is( $summary->{failed_tests},   0, 'failed tests' );
    is( $summary->{is_skipped_all}, 0, 'is skipped all' );
    is( $summary->{is_bailout},     0, 'is bailout' );

    # old members
    is( $summary->{plan}{number}, 3, 'summary - planned tests' );
    is( $summary->{tests}, 3,        'summary - ran tests'     );
    is( $summary->{fail}, 0,         'summary - fail number'   );
    is( $summary->{bailout}, undef,  'summary - not bailout'   );
};

subtest 'tree' => sub {
    plan tests => 3;

    is( $tree->{testline}[0]{description}, 'first test', 'test description' );
    is( $tree->{testline}[1]{subtest}{testline}[1]{subtest}{testline}[0]{description}, 'sub sub test', 'sub sub test description' );
    is( $tree->{testline}[1]{subtest}{testline}[2]{subtest}{testline}[0]{description}, 'sub sub sub test', 'sub sub sub test description' );
};

subtest 'iterator' => sub {
    plan tests => 8;
    
    my $iterator = $taptree->create_tap_tree_iterator( subtest => 1 );

    my @descriptions = ( 'first test', 'second test', 'first sub test', 'second sub test', 'sub sub test', 'third sub test', 'sub sub sub test', 'third test' );

    for my $description ( @descriptions ) {
        my $result = $iterator->next;
        is( $result->{testline}{description}, $description, $description );
    }
};
