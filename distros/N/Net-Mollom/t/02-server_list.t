#!perl -T
use strict;
use warnings;
use Test::More (tests => 2);
use Net::Mollom;
use Exception::Class::TryCatch qw(catch);

my $mollom = Net::Mollom->new(
    private_key => '42d54a81124966327d40c928fa92de0f',
    public_key => '72446602ffba00c907478c8f45b83b03',
);
isa_ok($mollom, 'Net::Mollom');
$mollom->servers(['dev.mollom.com']);

SKIP: {
    my @servers;
    eval { @servers = $mollom->server_list };
    skip("Can't reach Mollom servers", 1) if catch(['Net::Mollom::CommunicationException']);
    cmp_ok($#servers, '>=', 1, 'got at least 1 server back');
}
