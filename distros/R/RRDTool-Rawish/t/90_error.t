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

subtest 'invalid rrdtool path' => sub {
    like exception {
        my $rrd = RRDTool::Rawish->new(
            rrdtool_path => "./abcdefghijklmn",
            rrdfile      => $rrd_file,
        );
    }, qr/^Cannot execute/;
};

subtest no_rrdfile => sub {
    my $rrd = rrd_stub_new(command => $rrdtool_path);
    my $params = ['foo'];
    for (qw(create update dump restore lastupdate fetch info)) {
        like exception { $rrd->$_($params) }, qr(Require rrdfile);
    }
};

subtest parameter_type_mismatch => sub {
    my $rrd = rrd_stub_new(
        command => $rrdtool_path,
        rrdfile => $rrd_file,
    );

    my ($params, $opts);
    subtest invalid_param_type => sub {
        for (qw(create update xport)) {
            $params = 'not array';
            like exception { $rrd->$_($params) }, qr(Not ARRAY);
        }
        for (qw(create update dump xport)) {
            $params = [1, 2];
            $opts = 'not hash';
            like exception { $rrd->$_($params, $opts) }, qr(Not HASH);
        }
        for (qw(fetch restore)) {
            like exception { $rrd->$_() }, qr(Require);

            my $param = "scalar";
            $opts = 'not hash';
            like exception { $rrd->$_($param, $opts) }, qr(Not HASH);
        }

        { # graph
            like exception { $rrd->graph() }, qr(Require filename);
        }
    }
};

subtest 'rrdtool syntax error' => sub {
    unless (-x $rrdtool_path) {
        plan skip_all => "rrdtool command required for testing rrdtool syntax error";
    }

    my $rrd = RRDTool::Rawish->new(
        command => $rrdtool_path,
        rrdfile => $rrd_file,
    );

    for (qw(create update xport)) {
        $rrd->$_([], {'--invalid' => 'aaa' });
        like $rrd->errstr, qr/^ERROR:/;
    }
    for (qw(fetch restore)) {
        $rrd->$_("", {'--invalid' => 'aaa' });
        like $rrd->errstr, qr/^ERROR:/;
    }
    $rrd->dump({}, {'--invalid' => 'aaa' });
    like $rrd->errstr, qr/^ERROR:/;
};

done_testing;
