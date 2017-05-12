use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 4;

require_ok( 'TAP::Tree::Iterator' );

require TAP::Tree;

subtest 'no subtest' => sub {
    my $tap = <<'END';
1..2
ok
not ok
END

    my $taptree  = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $iterator = $taptree->create_tap_tree_iterator;

    my $next1 = $iterator->next;
    is( $next1->{testline}{result}, 1, 'ok' );
    is( $next1->{test}{plan}{number}, 2, 'plan test 1' );

    my $next2 = $iterator->next;
    is( $next2->{testline}{result}, 0, 'not ok' );
    is( $next2->{test}{plan}{number}, 2, 'plan test 2' );

    my $next3 = $iterator->next;
    is( $next3, undef, 'no test' );
};

subtest 'subtest complex' => sub {
    my $tap = <<'END';
1..3
ok 1 - first test
    ok 1 - first sub test
        ok 1 - sub sub test
        1..1
    ok 2 - second sub test
        1..1
        ok 1 - sub sub sub test
    ok 3 - third sub test
    1..3
ok 2 - second test
ok 3 - third test
END

    my $taptree  = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $iterator = $taptree->create_tap_tree_iterator( subtest => 1 );

    my $tests = [
            { desc => 'first test',          indent => 0 },
            { desc => 'second test',         indent => 0 },
            { desc => 'first sub test',      indent => 1 },
            { desc => 'second sub test',     indent => 1 },
            { desc => 'sub sub test',        indent => 2 },
            { desc => 'third sub test',      indent => 1 },
            { desc => 'sub sub sub test',    indent => 2 },
            { desc => 'third test',          indent => 0 },
            { desc => undef                              },
        ];

    plan tests => ( scalar @{ $tests } ) * 2 - 1;

    for my $test ( @{ $tests } ) {
        if ( ! defined $test->{desc} ) {
            is( $iterator->next, undef, 'finished iterator' );
        } else {
            my $next = $iterator->next;
            is(
                    $next->{testline}{description},
                    $test->{desc},
                    'desc. - ' . $test->{desc}
                    );

            is(
                    $next->{indent},
                    $test->{indent},
                    'indent - ' . $test->{desc}
                    );
        } 
    }
};


subtest 'subtest simple' => sub {
    my $tap = <<'END';
        ok 1 - sub sub test
        1..1
    ok 1 - sub test
    1..1
ok 1 - test
1..1
END

    my $taptree  = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $iterator = $taptree->create_tap_tree_iterator( subtest => 1 );

    my $tests = [
            { desc => 'test',           indent => 0 },
            { desc => 'sub test',       indent => 1 },
            { desc => 'sub sub test',   indent => 2 },
            { desc => undef                         },
        ];

    plan tests => ( scalar @{ $tests } ) * 2 - 1;

    for my $test ( @{ $tests } ) {
        if ( ! defined $test->{desc} ) {
            is( $iterator->next, undef, 'finished iterator' );
        } else {
            my $next = $iterator->next;
            is(
                    $next->{testline}{description},
                    $test->{desc},
                    'desc. - ' . $test->{desc}
                    );

            is(
                    $next->{indent},
                    $test->{indent},
                    'indent - ' . $test->{desc}
                    );
        } 
    }
};
