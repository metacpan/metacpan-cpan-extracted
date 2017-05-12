use strict;
use warnings;

use Test::More tests => '18';
use Test::MockObject;

use HTTP::Response;

my $m;

BEGIN {
    use_ok( $m = 'Net::DNS::ValueDomain::DDNS' );
}

can_ok( $m, 'new' );
can_ok( $m, 'config' );
can_ok( $m, 'protocol' );
can_ok( $m, 'update' );
can_ok( $m, 'error' );
can_ok( $m, 'errstr' );
can_ok( $m, 'ua' );

my $res  = HTTP::Response->new;
my $mock = Test::MockObject->new;
$mock->fake_module(
    'LWP::UserAgent',
    new => sub { bless {}, shift },
    get => sub {$res}
);

my $ddns;
eval { $ddns = Net::DNS::ValueDomain::DDNS->new; };
isa_ok( $ddns, 'Net::DNS::ValueDomain::DDNS' );
isa_ok( ( $ddns->ua ), 'LWP::UserAgent' );

eval { $ddns->update; };
like( $@, qr/^domain is required/, 'update failed no domain parameter' );

eval { $ddns->update( domain => 'example.com' ); };
like( $@, qr/^password is required/, 'update failed no password parameter' );

$res->code(200);
$res->content('status=2 Invalid Domain and Password');

my $ret;
eval { $ret = $ddns->update( domain => 'example.com', password => '1234', ); };
is( $ret, undef, 'update failed' );
is( $ddns->errstr,
    'status=2 Invalid Domain and Password',
    'return collect error message'
);

$res->code(200);
$res->content('status=0 OK');

eval { $ret = $ddns->update( domain => 'example.com', password => '1234', ); };
is( $ret, 1, 'update successful normally' );

my $config = {
    domain   => 'example.net',
    password => 'hohoho',
    host     => 'www',
    ip       => '192.168.0.1',
};
eval {
    $ddns->{_config} = {};
    $ddns->config($config);
};
is_deeply( $ddns->config, $config, 'config ok' );

eval {
    $ddns->{_config} = {};
    $ddns->update($config);
};
is_deeply( $ddns->config, $config, 'config with update ok' );

eval { $ddns->update; };
is( $ret, 1, 'update successful with config' );
