# 00-basic.t
#
# Test suite for Set::Partition
# Make sure the basic stuff works
#
# copyright (C) 2006 David Landgren

use strict;

eval qq{ use Test::More tests => 6 };
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

use Set::Partition;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

diag( "testing Set::Partition v$Set::Partition::VERSION" );

{
    my $t = Set::Partition->new;
    ok( defined($t), 'new() defines ...' );
    ok( ref($t) eq 'Set::Partition', '... a Set::Partition object' );

    my $r = $t->next;
    ok( !defined($r), 'cannot arrange nothing' );
}

SKIP: {
    skip( 'Test::Pod not installed on this system', 1 )
        unless do {
            eval "use Test::Pod";
            $@ ? 0 : 1;
        };

    pod_file_ok( 'Partition.pm' );}

SKIP: {
    skip( 'Test::Pod::Coverage not installed on this system', 1 )
        unless do {
            eval "use Test::Pod::Coverage";
            $@ ? 0 : 1;
        };
    pod_coverage_ok( 'Set::Partition', 'POD coverage is go!' );
}

cmp_ok( $_, 'eq', $Unchanged, '$_ has not been altered' );
