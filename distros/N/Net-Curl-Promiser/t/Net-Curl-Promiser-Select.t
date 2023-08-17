#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use Net::Curl::Easy;

use Net::Curl::Promiser::Select;

use FindBin;
use lib "$FindBin::Bin/lib";

use MyServer;
use ClientTest;

plan tests => 2 + $ClientTest::TEST_COUNT;

{
    my $server = MyServer->new();

    my $promiser = Net::Curl::Promiser::Select->new();

    my $port = $server->port();

    my $all = ClientTest::run($promiser, $port);

    $_ = q<> for my ($rout, $wout, $eout);

    my $checked_get_fds;

    while ($promiser->handles()) {
        my $timeout = $promiser->get_timeout();

        ($rout, $wout, $eout) = $promiser->get_vecs();

        if ($^O eq 'solaris') {
            diag sprintf "rout: %v.08b; wout: %v.08b; timeout: %s\n", $rout, $wout, $timeout;
        }

        if (!$checked_get_fds && grep { tr<\0><>c } $rout, $wout) {
            $checked_get_fds++;

            my @fds = $promiser->get_fds();

            ok( 0 + @fds, 'get_fds() returns something when get_vecs() does' );

            is(
                0 + @fds,
                0 + $promiser->get_fds(),
                'get_fds() in scalar',
            );
        }

        if ($timeout && $timeout != -1) {
            my $got = select $rout, $wout, $eout, $timeout;

            die "select(): $!" if $got < 0;

            if ($eout =~ tr<\0><>c) {
                for my $fd ( $promiser->get_fds() ) {
                    next if !vec( $eout, $fd, 1 );
                    warn "problem (?) on FD $fd!";
                }
            }
        }

        $promiser->process($rout, $wout);
    }

    # Seen in Solaris with Perl 5.38+ and libcurl 8.0.1.
    if (!$checked_get_fds) {
        skip 'curl didn’t give us a chance to test get_fds()', 2;
    }

    $server->finish();
}

done_testing();

1;
