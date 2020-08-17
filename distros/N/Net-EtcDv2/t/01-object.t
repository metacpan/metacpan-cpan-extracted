use 5.30.0;
use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok('Net::EtcDv2');
}

SKIP: {
    skip "missing env vars(ETCD_HOST, ETCD_PORT)", 1,
        unless (exists $ENV{'ETCD_HOST'} && exists $ENV{'ETCD_PORT'});

    # a little prettier debug output
    my $o = Net::EtcDv2->new(
        'host' => $ENV{'ETCD_HOST'},
        'port' => $ENV{'ETCD_PORT'}
    );
    isa_ok($o, 'Net::EtcDv2');
}
