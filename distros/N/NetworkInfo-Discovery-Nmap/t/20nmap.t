use strict;
use Test::More;
use NetworkInfo::Discovery::Nmap;
use Socket;
use Sys::Hostname;

my($name,$aliases,$addrtype,$length,@addrs) = gethostbyname(hostname);
plan skip_all => "Can't find a network interface with an IP address" unless @addrs;
@addrs = map { inet_ntoa($_) } @addrs;
plan 'no_plan';

my $obj = undef;
my @hosts = ();

for my $addr (@addrs) {
    $obj = new NetworkInfo::Discovery::Nmap hosts => [ $addr ];
    ok( defined $obj );
    eval { $obj->do_it };
    is( $@, '' );
    eval { @hosts = $obj->get_interfaces };
    is( $@, '' );
    ok( scalar @hosts == 1 );

    for my $host (@hosts) {
        is( $host->{ip}, $addr );
        
        for my $service (@{$host->{services}}) {
            like( $service->{port}, qr/^\d+$/ );
            like( $service->{protocol}, qr/^(?:tcp|udp)$/ );
            like( $service->{state}, qr/^(?:open|close|filtered)$/ );
            like( $service->{name}, qr/^[\w-]+$/ );
            
            if(defined $service->{application}) {
                is( ref $service->{application}, 'HASH' );
                ok( defined $service->{application}{product} );
                ok( defined $service->{application}{version} );
                ok( defined $service->{application}{extrainfo} );
            }
        }
    }
}