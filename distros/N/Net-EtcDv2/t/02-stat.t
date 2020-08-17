use 5.30.0;
use strict;
use warnings;
use utf8;
use English;

use Test::More tests => 5;

use Data::Dumper;
use Try::Tiny;
use Throw qw(classify);

BEGIN {
    use_ok('Net::EtcDv2');
}

SKIP: {
    skip "missing env vars(ETCD_HOST, ETCD_PORT)", 4,
        unless (exists $ENV{'ETCD_HOST'} && exists $ENV{'ETCD_PORT'});

    my $o = Net::EtcDv2->new(
        'host' => $ENV{'ETCD_HOST'},
        'port' => $ENV{'ETCD_PORT'},
        'debug' => $ENV{'DEBUG'},
        'user'  => $ENV{'user'},
        'password' => $ENV{'password'}
    );
    my $r = $o->stat('/');

    ok(defined $r);
    ok($r->{'type'} eq 'dir');
    ok($r->{'ace'}  eq "*:POST, GET, OPTIONS, PUT, DELETE");

    # now test for something that doesn't exist
    try {
        $r = $o->stat('/foo');
    } catch {
        classify $ARG, {
            default => sub {
                ok($ARG->{'type'} eq 404);
            }
        };
    };
}
