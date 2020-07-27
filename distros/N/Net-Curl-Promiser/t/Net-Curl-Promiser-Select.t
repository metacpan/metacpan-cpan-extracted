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

plan tests => $ClientTest::TEST_COUNT;

{
    my $server = MyServer->new();

    my $promiser = Net::Curl::Promiser::Select->new();

    my $port = $server->port();

    my $all = ClientTest::run($promiser, $port);

    $_ = q<> for my ($rout, $wout, $eout);

    while ($promiser->handles()) {
        my $timeout = $promiser->get_timeout();

        if ($timeout && $timeout != -1) {
            ($rout, $wout, $eout) = $promiser->get_vecs();

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

    $server->finish();
}

done_testing();

1;
