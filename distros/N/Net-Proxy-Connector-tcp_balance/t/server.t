#!/usr/bin/perl

use Test::More skip_all => "need to fix this set of tests (plz send pull request)";

use Net::Proxy::Connector::tcp_balance;

use Test::Fork;
use Test::Warn;

fork_ok(2, sub{
    sleep 1;
    IO::Socket::INET->new('localhost:6789')->connected();
    done_testing();
});

local $SIG{ALRM} = sub {
    warnings_exist { } [qr/.*failed.*/], "expected warning occurred";
    done_testing();
    exit 0;
};
alarm 2;

my $proxy = Net::Proxy->new(
    {   in  => { type => 'tcp', port => '6789' },
        out => { type => 'tcp_balance', hosts => [ 'host1', 'host2' ], port => '25', verbose => 1 },
    }
);

# register the proxy object
$proxy->register();

# and now proxy connections indefinitely
Net::Proxy->mainloop();
