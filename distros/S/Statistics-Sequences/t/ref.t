use strict;
use warnings;
use Test::More tests => 6;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::Sequences') }

my $seq = new_ok('Statistics::Sequences');
my @dat = (qw/H H H H H H H H H H D H D D D D H H H H H H H H H/);

# Load by array-ref:
eval { $seq->load( \@dat ); };
ok( !$@ );
eval { $seq->unload(); };
ok( !$@ );

# check minimal integration with Statistics::Data parent's load(), add() and access() methods:
$seq->load( coinflip => \@dat, otherdat => [ 1, 2, 3 ] );
my $data = $seq->access( label => 'coinflip' );
ok( join( q{}, @{$data} ) eq join( q{}, @dat ), 'Failed to access data' );
$seq->add( otherdat => [4] );
$data = $seq->access( label => 'otherdat' );
my $sum = 0;
$sum += $_ foreach @{$data};
ok( $sum == 10, "Failed to read data" );

#diag($seq->observed(stat => 'runs', data => \@dat));
