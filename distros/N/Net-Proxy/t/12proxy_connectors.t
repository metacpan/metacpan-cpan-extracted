use strict;
use warnings;
use Test::More tests => 5;
use Net::Proxy;

my $proxy = Net::Proxy->new(
    {
        in  => { type => 'dummy' },
        out => { type => 'dummy' },
    }
);

isnt( $proxy->in_connector(), $proxy->out_connector(), 'Distinct connectors' );

ok( $proxy->in_connector()->is_in(),   'in_connector() is "in"' );
ok( !$proxy->out_connector()->is_in(), 'out_connector() is not "in"' );
ok( !$proxy->in_connector()->is_out(), 'in_connector() is not "out"' );
ok( $proxy->out_connector()->is_out(), 'out_connector() is "out"' );
