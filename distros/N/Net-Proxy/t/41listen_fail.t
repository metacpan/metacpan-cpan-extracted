use Test::More;
use strict;
use warnings;
use t::Util;

use Net::Proxy;

plan tests => my $tests = 1;

# lock 2 ports
my @free = find_free_ports(2);

SKIP: {
    skip "Not enough available ports", $tests if @free < 2;

    my ( $proxy_port, $server_port ) = @free;

    my $server = listen_on_port( $proxy_port )
        or skip "Failed to lock port $proxy_port", $tests;

    my $proxy = Net::Proxy->new(
        {   in => {
                type => 'tcp',
                host => 'localhost',
                port => $proxy_port,
            },
            out => {
                type => 'tcp',
                host => 'localhost',
                port => $server_port,
            },
        },
    );

    $proxy->register();
    eval { Net::Proxy->mainloop(); };
    like( $@, qr/^Can't listen on localhost port \d+: /, 'Port in use' );
}

