#!perl -w

use Test::More tests => 29;
use Test::Exception;
use Test::Deep;
use Clone 'clone';
use File::Spec;
use File::Basename qw(dirname);

BEGIN {
  use_ok('RRD::Editor') or BAIL_OUT("cannot load the module");
}

note("Testing RRD::Editor $RRD::Editor::VERSION, Perl $], $^X");

new_ok ( "RRD::Editor");

my $source = { 'rrd' => {
        'dataloaded'    => 1,
        'ds_cnt'        => 0,
        'rra_cnt'       => 3,
        'rra' => [ { 'idx' => 0 }, { 'idx' => 1 }, { 'idx' => 2 } ],
    }};

my $rrd = clone($source);
bless $rrd, 'RRD::Editor';

is($rrd->num_RRAs(), 3, 'Checking rra_cnt before delete_RRA()');
throws_ok { $rrd->resize_RRA(-1) } qr/RRA index out of range/, 'Expecting exception for delete_RRA(-1)';
throws_ok { $rrd->resize_RRA(3) } qr/RRA index out of range/, 'Expecting exception for delete_RRA(3)';

$source = { 'encoding' => 'native-single', 'rrd' => {
        'dataloaded'    => 1,
        'ds_cnt'        => 0,
        'rra_cnt'       => 1,
        'rra' => [ { 'row_cnt' => 10, 'ptr' => 6, 'data' => [ 3, 4, 5, 6, 7, 8, 9, 0, 1, 2 ] } ],
    }};


$rrd = clone($source); bless $rrd, 'RRD::Editor';
lives_ok { $rrd->resize_RRA(0, 12); } 'Expecting success for resize_RRA(0, 12)';
is($rrd->RRA_numrows(0), 12, 'Checking RRA_numrows after resize_RRA(0, 12)');
is(scalar(@{$rrd->{'rrd'}->{'rra'}[0]->{'data'}}), 12, 'Checking data array size equals RRA_numrows');
cmp_deeply($rrd->{'rrd'}->{'rra'}[0]->{'data'}, [ 3, 4, 5, 6, 7, 8, 9, '', '', 0, 1, 2 ], 'Checking data in array after resizing to 12');

lives_ok { $rrd->resize_RRA(0, 10); } 'Expecting success for resize_RRA(0, 10)';
is($rrd->RRA_numrows(0), 10, 'Checking RRA_numrows after resize_RRA(0, 10)');
is(scalar(@{$rrd->{'rrd'}->{'rra'}[0]->{'data'}}), 10, 'Checking data array size equals RRA_numrows');
cmp_deeply($rrd->{'rrd'}->{'rra'}[0]->{'data'}, [ 3, 4, 5, 6, 7, 8, 9, 0, 1, 2 ], 'Checking data in array after resizing to 10');

lives_ok { $rrd->resize_RRA(0, 8); } 'Expecting success for resize_RRA(0, 8)';
is($rrd->RRA_numrows(0), 8, 'Checking RRA_numrows after resize_RRA(0, 8)');
is(scalar(@{$rrd->{'rrd'}->{'rra'}[0]->{'data'}}), 8, 'Checking data array size equals RRA_numrows');
cmp_deeply($rrd->{'rrd'}->{'rra'}[0]->{'data'}, [ 3, 4, 5, 6, 7, 8, 9, 2 ], 'Checking data in array after resizing to 8');

lives_ok { $rrd->resize_RRA(0, 4); } 'Expecting success for resize_RRA(0, 4)';
is($rrd->RRA_numrows(0), 4, 'Checking RRA_numrows after resize_RRA(0, 4)');
is(scalar(@{$rrd->{'rrd'}->{'rra'}[0]->{'data'}}), 4, 'Checking data array size equals RRA_numrows');
cmp_deeply($rrd->{'rrd'}->{'rra'}[0]->{'data'}, [ 6, 7, 8, 9, ], 'Checking data in array after resizing to 4');

$rrd->{'rrd'}->{'rra'}[0]->{'ptr'} = scalar(@{$rrd->{'rrd'}->{'rra'}[0]->{'data'}})-1;
lives_ok { $rrd->resize_RRA(0, 2); } 'Expecting success for resize_RRA(0, 2)';
is($rrd->RRA_numrows(0), 2, 'Checking RRA_numrows after resize_RRA(0, 2)');
is(scalar(@{$rrd->{'rrd'}->{'rra'}[0]->{'data'}}), 2, 'Checking data array size equals RRA_numrows');
cmp_deeply($rrd->{'rrd'}->{'rra'}[0]->{'data'}, [ 8, 9, ], 'Checking data in array after resizing to 2');

$rrd = clone($source);
$rrd->{'rra'}[0]->{'data'} = [ 3, 4, 5, 6, 7, 8, 9, -2, -1, 0, 1, 2 ];
$rrd->{'rra'}[0]->{'row_cnt'} = 12;
bless $rrd, 'RRD::Editor';
lives_ok { $rrd->resize_RRA(0, 3); } 'Expecting success for resize_RRA(0, 3)';
is($rrd->RRA_numrows(0), 3, 'Checking RRA_numrows after resize_RRA(0, 3)');
is(scalar(@{$rrd->{'rrd'}->{'rra'}[0]->{'data'}}), 3, 'Checking data array size equals RRA_numrows');
cmp_deeply($rrd->{'rrd'}->{'rra'}[0]->{'data'}, [ 7, 8, 9, ], 'Checking data in array after resizing to 3');


done_testing();
