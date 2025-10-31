#!perl
use 5.020;
use Test2::V0 '-no_srand';
use Data::Dumper;
use Mojo::UserAgent::Paranoid;
use Net::DNS::Paranoid;

my $io = Mojo::IOLoop->singleton;
my $ua = Mojo::UserAgent::Paranoid->new( ioloop => $io );

my @to_be_blocked = (
    'localhost',
    '127.0.0.1',
    '127.3.2.1',
);

if( Net::DNS::Paranoid->VERSION gt '0.15' ) {
    push @to_be_blocked,
    '[::1]',
    '[::0000:1]', # sneaky
    '--1.sslip.io', # resolves to ::1
    ;
}

my @to_be_routed = (
    'sslip.io', # sslip.io IPv4 address
);
if( Net::DNS::Paranoid->VERSION gt '0.15' ) {
    push @to_be_routed,
    '2a01-4f8-c17-b8f--2.sslip.io', # sslip.io IPv6 address
    ;
}

for my $addr (@to_be_blocked) {
    my $res = $ua->get("http://$addr/example");
    ok $res->res->error, "Connecting to '$addr' raises an error"
        or diag Dumper $res->res;
    isnt $res->res->error->{message}, 'Connection refused', "Connecting to '$addr' does not actually try to connect";
    like $res->res->error->{message}, qr/\bBad host\b|\bCan't resolve\b/, "Connecting to '$addr' raises an error";
}

for my $addr (@to_be_routed) {
    my $res = $ua->get("https://$addr/");
    ok $res->res->is_success, "Connecting to '$addr' succeeds"
        or diag Dumper $res->res;

}

done_testing();
