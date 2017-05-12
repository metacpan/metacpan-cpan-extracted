use Test::More tests => 3;

use_ok('Net::Proxy::Connector::tcp_balance');

# proxy connections from localhost:6789 to remotehost:9876
# using standard TCP connections
my $proxy = Net::Proxy->new(
    {   in  => { type => 'tcp', port => '6789' },
        out => { type => 'tcp_balance', hosts => [ 'host1', 'host2' ], port => '25' },
    }
);
ok($proxy);
 
# register the proxy object
ok($proxy->register());
 
# and now proxy connections indefinitely
#Net::Proxy->mainloop();

