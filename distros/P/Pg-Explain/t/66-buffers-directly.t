#!perl

use Test::More;
use Test::Deep;

use Pg::Explain::Buffers;

plan 'tests' => 29;

my $ex1 = Pg::Explain::Buffers->new( 'Buffers: shared hit=1 read=2 dirtied=3 written=4, local hit=5 read=6 dirtied=7 written=8, temp read=9 written=10' );
my $ex2 = Pg::Explain::Buffers->new( 'Buffers: shared hit=7' );
my $ex3 = Pg::Explain::Buffers->new(
    {
        "Shared Hit Blocks"     => 1,
        "Shared Read Blocks"    => 2,
        "Shared Dirtied Blocks" => 3,
        "Shared Written Blocks" => 4,
        "Local Hit Blocks"      => 5,
        "Local Read Blocks"     => 6,
        "Local Dirtied Blocks"  => 7,
        "Local Written Blocks"  => 8,
        "Temp Read Blocks"      => 9,
        "Temp Written Blocks"   => 10,
        "I/O Read Time"         => 11,
        "I/O Write Time"        => 12,
    }
);
my $ex4 = Pg::Explain::Buffers->new(
    {
        "Shared Hit Blocks"     => 0,
        "Shared Read Blocks"    => 0,
        "Shared Dirtied Blocks" => 0,
        "Shared Written Blocks" => 0,
        "Local Hit Blocks"      => 0,
        "Local Read Blocks"     => 1,
        "Local Dirtied Blocks"  => 0,
        "Local Written Blocks"  => 0,
        "Temp Read Blocks"      => 0,
        "Temp Written Blocks"   => 0,
        "I/O Read Time"         => 0,
        "I/O Write Time"        => '0.000',
    }
);

cmp_deeply(
    {
        'shared' => { 'hit'  => 1, 'read'    => 2, 'dirtied' => 3, 'written' => 4, },
        'local'  => { 'hit'  => 5, 'read'    => 6, 'dirtied' => 7, 'written' => 8, },
        'temp'   => { 'read' => 9, 'written' => 10, },
    },
    $ex1->get_struct(),
    'Test 1 struct'
);
cmp_deeply(
    { 'shared' => { 'hit' => 7, }, },
    $ex2->get_struct(),
    'Test 2 struct'
);
cmp_deeply(
    {
        'shared'  => { 'hit'  => 1,  'read'    => 2, 'dirtied' => 3, 'written' => 4, },
        'local'   => { 'hit'  => 5,  'read'    => 6, 'dirtied' => 7, 'written' => 8, },
        'temp'    => { 'read' => 9,  'written' => 10, },
        'timings' => { 'read' => 11, 'write'   => 12, 'info' => 'I/O Timings: read=11.000 write=12.000' },
    },
    $ex3->get_struct(),
    'Test 3 struct'
);
cmp_deeply(
    { 'local' => { 'read' => 1 } },
    $ex4->get_struct(),
    'Test 4 struct'
);
is(
    Pg::Explain::Buffers->new( {} )->get_struct(),
    undef,
    'Test 5 struct'
  );

is(
    $ex1->as_text,
    "Buffers: shared hit=1 read=2 dirtied=3 written=4, local hit=5 read=6 dirtied=7 written=8, temp read=9 written=10",
    'Test 6 as_text call'
  );
is(
    $ex2->as_text,
    "Buffers: shared hit=7",
    'Test 7 as_text call'
  );
is(
    $ex3->as_text,
    "Buffers: shared hit=1 read=2 dirtied=3 written=4, local hit=5 read=6 dirtied=7 written=8, temp read=9 written=10\nI/O Timings: read=11.000 write=12.000",
    'Test 8 as_text call'
  );
is(
    $ex4->as_text,
    "Buffers: local read=1",
    'Test 9 as_text call'
  );

my $ex1_timing = 'I/O Timings: read=1.200 write=3.400';
my $ex2_timing = 'I/O Timings: read=5.600';
$ex1->add_timing( $ex1_timing );
$ex2->add_timing( $ex2_timing );

cmp_deeply(
    {
        'shared'  => { 'hit'  => 1,   'read'    => 2, 'dirtied' => 3, 'written' => 4, },
        'local'   => { 'hit'  => 5,   'read'    => 6, 'dirtied' => 7, 'written' => 8, },
        'temp'    => { 'read' => 9,   'written' => 10, },
        'timings' => { 'read' => 1.2, 'write'   => 3.4, 'info' => $ex1_timing },
    },
    $ex1->get_struct(),
    'Test 10 struct, post add_timing'
);
cmp_deeply(
    {
        'shared'  => { 'hit'  => 7, },
        'timings' => { 'read' => 5.6, 'info' => $ex2_timing },
    },
    $ex2->get_struct(),
    'Test 11 struct, post add_timing'
);
is(
    $ex1->as_text,
    "Buffers: shared hit=1 read=2 dirtied=3 written=4, local hit=5 read=6 dirtied=7 written=8, temp read=9 written=10\nI/O Timings: read=1.200 write=3.400",
    'Test 12 as_text call, post add_timing',
  );
is(
    $ex2->as_text,
    "Buffers: shared hit=7\nI/O Timings: read=5.600",
    'Test 13 as_text call, post add_timing'
  );

# Subtraction
is(
    ( Pg::Explain::Buffers->new( 'Buffers: shared hit=7' ) - Pg::Explain::Buffers->new( {} ) )->as_text,
    'Buffers: shared hit=7',
    'Subtraction test 1'
  );
is(
    Pg::Explain::Buffers->new( 'Buffers: shared hit=7' ) - Pg::Explain::Buffers->new( 'Buffers: shared hit=7' ),
    undef,
    'Subtraction test 2'
  );
is(
    ( Pg::Explain::Buffers->new( 'Buffers: shared hit=7, local read=5' ) - Pg::Explain::Buffers->new( 'Buffers: shared read=2, local read=3' ) )->as_text,
    'Buffers: shared hit=7, local read=2',
    'Subtraction test 3'
  );
is(
    ( Pg::Explain::Buffers->new( 'Buffers: shared hit=7, local read=5' ) - Pg::Explain::Buffers->new( 'Buffers: shared hit=10, local read=3' ) )->as_text,
    'Buffers: local read=2',
    'Subtraction test 4'
  );

# Addition
is(
    ( Pg::Explain::Buffers->new( 'Buffers: shared hit=7' ) + Pg::Explain::Buffers->new( {} ) )->as_text,
    'Buffers: shared hit=7',
    'Addition test 1'
  );
is(
    ( Pg::Explain::Buffers->new( 'Buffers: shared hit=7' ) + Pg::Explain::Buffers->new( 'Buffers: shared hit=7' ) )->as_text,
    'Buffers: shared hit=14',
    'Addition test 2'
  );
is(
    ( Pg::Explain::Buffers->new( 'Buffers: shared hit=7, local read=5' ) + Pg::Explain::Buffers->new( 'Buffers: shared read=2, local read=3' ) )->as_text,
    'Buffers: shared hit=7 read=2, local read=8',
    'Addition test 3'
  );
is(
    ( Pg::Explain::Buffers->new( 'Buffers: shared hit=7, local read=5' ) + Pg::Explain::Buffers->new( 'Buffers: shared hit=10, local read=3' ) )->as_text,
    'Buffers: shared hit=17, local read=8',
    'Addition test 4'
  );

my $b1 = Pg::Explain::Buffers->new( 'Buffers: shared hit=7' );
my $b2 = Pg::Explain::Buffers->new( 'Buffers: local read=5' );
cmp_deeply( [ qw( shared ) ], [ sort keys %{ $b1->data } ], 'Keys in buffers data, b1, before math (+)' );
cmp_deeply( [ qw( local ) ],  [ sort keys %{ $b2->data } ], 'Keys in buffers data, b2, before math (+)' );
my $b3 = $b1 + $b2;
cmp_deeply( [ qw( shared ) ],       [ sort keys %{ $b1->data } ], 'Keys in buffers data, b1, after math (+)' );
cmp_deeply( [ qw( local ) ],        [ sort keys %{ $b2->data } ], 'Keys in buffers data, b2, after math (+)' );
cmp_deeply( [ qw( local shared ) ], [ sort keys %{ $b3->data } ], 'Keys in buffers data, b3, after math (+)' );
$b3 = $b1 - $b2;
cmp_deeply( [ qw( shared ) ], [ sort keys %{ $b1->data } ], 'Keys in buffers data, b1, after math (+)' );
cmp_deeply( [ qw( local ) ],  [ sort keys %{ $b2->data } ], 'Keys in buffers data, b2, after math (+)' );
cmp_deeply( [ qw( shared ) ], [ sort keys %{ $b3->data } ], 'Keys in buffers data, b3, after math (+)' );

exit;

