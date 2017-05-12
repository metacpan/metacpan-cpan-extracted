use strict;
use Test::More;
use NetworkInfo::Discovery::NetBIOS;
use Socket;
use Sys::Hostname;

my($name,$aliases,$addrtype,$length,@addrs) = gethostbyname(hostname);
plan skip_all => "Can't find any network interface with an IP address" unless @addrs;
@addrs = map { inet_ntoa($_) } @addrs;
plan tests => 11 * scalar @addrs;

my $obj = undef;
my @hosts = ();

for my $addr (@addrs) {
    $obj = new NetworkInfo::Discovery::NetBIOS hosts => [ $addr ];
    ok( defined $obj );
    eval { $obj->do_it };
    is( $@, '' );
    eval { @hosts = $obj->get_interfaces };
    is( $@, '' );
    ok( scalar @hosts );

    for my $host (@hosts) {
        is( $host->{ip}, $addr );
        ok( defined $host->{netbios} );
        is( ref $host->{netbios}, 'HASH' );
        ok( defined $host->{netbios}{node} );
        ok( length $host->{netbios}{node} );
        ok( defined $host->{netbios}{zone} );
        ok( length $host->{netbios}{node} );
    }
}
