#!perl -w

use Test::More tests => 23;
use Test::Exception;
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
        'rra_cnt'       => 3,
        'rra' => [ { 'idx' => 0 }, { 'idx' => 1 }, { 'idx' => 2 } ],
    }};

my $rrd = clone($source);
bless $rrd, 'RRD::Editor';

is($rrd->num_RRAs(), 3, 'Checking rra_cnt before delete_RRA()');
throws_ok { $rrd->delete_RRA(-1) } qr/RRA index out of range/, 'Expecting exception for delete_RRA(-1)';
throws_ok { $rrd->delete_RRA(3) } qr/RRA index out of range/, 'Expecting exception for delete_RRA(3)';

my $c;

$c = clone($rrd);
lives_ok { $c->delete_RRA(0); } 'Expecting success for delete_RRA(0)';
is($c->num_RRAs(), 2, 'Checking num_RRAs after delete_RRA(0)');
is(scalar(@{$c->{'rrd'}->{'rra'}}), 2, 'Checking array size equals num_RRAs');
is($c->{'rrd'}->{'rra'}[0]->{'idx'}, 1, 'Checking element at index 1 shifted to index 0');
is($c->{'rrd'}->{'rra'}[1]->{'idx'}, 2, 'Checking element at index 2 shifted to index 1');

$c = clone($rrd);
lives_ok { $c->delete_RRA(1); } 'Expecting success for delete_RRA(1)';
is($c->num_RRAs(), 2, 'Checking num_RRAs after delete_RRA(1)');
is(scalar(@{$c->{'rrd'}->{'rra'}}), 2, 'Checking array size equals num_RRAs');
is($c->{'rrd'}->{'rra'}[0]->{'idx'}, 0, 'Checking element at index 0 retained');
is($c->{'rrd'}->{'rra'}[1]->{'idx'}, 2, 'Checking element at index 2 shifted to index 1');

$c = clone($rrd);
lives_ok { $c->delete_RRA(2); } 'Expecting success for delete_RRA(2)';
is($c->num_RRAs(), 2, 'Checking num_RRAs after delete_RRA(1)');
is(scalar(@{$c->{'rrd'}->{'rra'}}), 2, 'Checking array size equals num_RRAs');
is($c->{'rrd'}->{'rra'}[0]->{'idx'}, 0, 'Checking element at index 0 retained');
is($c->{'rrd'}->{'rra'}[1]->{'idx'}, 1, 'Checking element at index 1 retanied');

$c->delete_RRA(0);
$c->delete_RRA(0);
is($c->num_RRAs(), 0, 'Checking num_RRAs after deletion of all RRAs');
is(scalar(@{$c->{'rrd'}->{'rra'}}), 0, 'Checking array size equals num_RRAs');
throws_ok { $c->delete_RRA(0) } qr/RRA index out of range/, 'Expecting exception for delete_RRA(0) for no RRAs';

done_testing();
