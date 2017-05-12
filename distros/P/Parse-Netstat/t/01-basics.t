#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::Slurper qw(read_text);
use Parse::Netstat qw(parse_netstat);
use Test::More 0.98;

sub test_parse {
    my (%args) = @_;
    my $name = $args{name};
    my $data = $args{data};

    subtest $name => sub {
        my $res;
        my $eval_err;
        eval {
            my %fargs = (output => $data, %{$args{args} // {}});
            $res = parse_netstat(%fargs);
        };
        $eval_err = $@;

        if ($args{dies}) {
            ok($eval_err, "dies");
        } else {
            ok(!$eval_err, "doesn't die") or diag $eval_err;
        }

        if (exists $args{status}) {
            is($res->[0], $args{status}, "result") or diag explain $res;
        }

        if ($res->[0] == 200) {
            my $parsed = $res->[2];
            my $conns  = $parsed->{active_conns};
            my $num_tcp  = grep {($_->{proto} // '') =~ /tcp[46]?/}  @$conns;
            my $num_udp  = grep {($_->{proto} // '') =~ /udp[46]?/}  @$conns;
            my $num_unix = grep {($_->{proto} // '') =~ /unix/} @$conns;
            if (defined $args{num_tcp}) {
                is($num_tcp, $args{num_tcp}, "num_tcp=$args{num_tcp}");
            }
            if (defined $args{num_udp}) {
                is($num_udp, $args{num_udp}, "num_udp=$args{num_udp}");
            }
            if (defined $args{num_unix}) {
                is($num_unix, $args{num_unix}, "num_unix=$args{num_unix}");
            }
        } else {
            ok(0, "result is not 200 ($res->[0])");
            diag explain $res;
        }

        if ($args{post_parse}) {
            $args{post_parse}->($res);
        }
    };
}

subtest "linux" => sub {
    my $data = read_text("$Bin/../share/netstat-samples/netstat-anp-linux");
    test_parse(name=>'all'    , data=>$data, args=>{flavor=>"linux"},          num_tcp=>10, num_udp=>4, num_unix=>3);
    test_parse(name=>'no tcp' , data=>$data, args=>{flavor=>"linux", tcp=>0},  num_tcp=>0 , num_udp=>4, num_unix=>3);
    test_parse(name=>'no udp' , data=>$data, args=>{flavor=>"linux", udp=>0},  num_tcp=>10, num_udp=>0, num_unix=>3);
    test_parse(name=>'no unix', data=>$data, args=>{flavor=>"linux", unix=>0}, num_tcp=>10, num_udp=>4, num_unix=>0);
};

subtest "freebsd" => sub {
    my $data = read_text("$Bin/../share/netstat-samples/netstat-an-freebsd-10.1");
    test_parse(name=>'all'    , args=>{flavor=>"freebsd"},          data=>$data, num_tcp=>23, num_udp=>13, num_unix=>27);
    test_parse(name=>'no tcp' , args=>{flavor=>"freebsd", tcp=>0},  data=>$data, num_tcp=> 0, num_udp=>13, num_unix=>27);
    test_parse(name=>'no udp' , args=>{flavor=>"freebsd", udp=>0},  data=>$data, num_tcp=>23, num_udp=> 0, num_unix=>27);
    test_parse(name=>'no unix', args=>{flavor=>"freebsd", unix=>0}, data=>$data, num_tcp=>23, num_udp=>13, num_unix=> 0);
};

subtest "darwin" => sub {
    my $data = read_text("$Bin/../share/netstat-samples/netstat-an-darwin");
    test_parse(name=>'all'    , args=>{flavor=>"darwin"},          data=>$data, num_tcp=>3, num_udp=>3, num_unix=>4);
    test_parse(name=>'no tcp' , args=>{flavor=>"darwin", tcp=>0},  data=>$data, num_tcp=>0, num_udp=>3, num_unix=>4);
    test_parse(name=>'no udp' , args=>{flavor=>"darwin", udp=>0},  data=>$data, num_tcp=>3, num_udp=>0, num_unix=>4);
    test_parse(name=>'no unix', args=>{flavor=>"darwin", unix=>0}, data=>$data, num_tcp=>3, num_udp=>3, num_unix=>0);
};

subtest "solaris" => sub {
    my $data = read_text("$Bin/../share/netstat-samples/netstat-n-solaris");
    test_parse(name=>'all'    , args=>{flavor=>"solaris"},          data=>$data, num_tcp=>6, num_udp=>3, num_unix=>11);
    test_parse(name=>'no tcp' , args=>{flavor=>"solaris", tcp=>0},  data=>$data, num_tcp=>0, num_udp=>3, num_unix=>11);
    test_parse(name=>'no udp' , args=>{flavor=>"solaris", udp=>0},  data=>$data, num_tcp=>6, num_udp=>0, num_unix=>11);
    test_parse(name=>'no unix', args=>{flavor=>"solaris", unix=>0}, data=>$data, num_tcp=>6, num_udp=>3, num_unix=> 0);
};

subtest "win32" => sub {
    my $data = read_text("$Bin/../share/netstat-samples/netstat-anp-win32");
    test_parse(name=>'all'   , args=>{flavor=>"win32"},         data=>$data, num_tcp=>4, num_udp=>2);
    test_parse(name=>'no tcp', args=>{flavor=>"win32", tcp=>0}, data=>$data, num_tcp=>0, num_udp=>2);
    test_parse(name=>'no udp', args=>{flavor=>"win32", udp=>0}, data=>$data, num_tcp=>4, num_udp=>0);
};

DONE_TESTING:
done_testing();
