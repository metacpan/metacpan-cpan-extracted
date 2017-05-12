use utf8;
use strict;
use warnings;
use lib lib => 't/lib';

use Test::More;
use Test::Fatal;

use RRDTool::Rawish;
use RRDTool::Rawish::Test qw(rrd_stub_new);

my $rrdtool_path = $RRDTool::Rawish::Test::RRDTOOL_PATH;
my $rrd_file     = './rrd_test.rrd';

subtest sanitize => sub {
    unless (-x $rrdtool_path) {
        plan skip_all => "rrdtool command required for testing rrdtool syntax error";
    }
    my $rrd = rrd_stub_new(
        command => $rrdtool_path,
        rrdfile => $rrd_file,
    );
    $rrd->_system("$rrdtool_path create $rrd_file --step 10; rm hoge");
    like $rrd->errstr, qr/^ERROR: can\'t parse argument/;

    $rrd->_system("$rrdtool_path create $rrd_file --step 10 && rm hoge");
    like $rrd->errstr, qr/^ERROR: can\'t parse argument/;

    $rrd->_system("$rrdtool_path create $rrd_file --step 10 || rm hoge");
    like $rrd->errstr, qr/^ERROR: can\'t parse argument/;
};

done_testing;
