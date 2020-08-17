use 5.30.0;
use strict;
use warnings;

use boolean;
use Data::Dumper;
use JSON;
use Test::More tests => 5;

use Net::EtcDv2;

BEGIN {
    use_ok('Net::EtcDv2');
}

SKIP: {
    skip "missing env vars(ETCD_HOST, ETCD_PORT)", 4,
        unless (exists $ENV{'ETCD_HOST'} && exists $ENV{'ETCD_PORT'});

    my $debug = false;
    if (exists $ENV{'DEBUG'} && $ENV{'DEBUG'} eq 1) {
        $debug = true;
    } else {
        $debug = false;
    }

    # a little prettier debug output
    my $o = Net::EtcDv2->new(
        'host' => $ENV{'ETCD_HOST'},
        'port' => $ENV{'ETCD_PORT'},
        'debug' => $ENV{'DEBUG'} || 0
    );

    ok(defined $o);
    my ($x, $r) = $o->rmdir('/myTestDir', false);
    say "DEBUG: rmdir output: x: " . Dumper($x) . "DEBUG: output: r: ". Dumper($r) if $debug;
    # now lets inspect the output
    my $content = decode_json($r);
    say "DEBUG: content: ". Dumper($content);
    ok($content->{'action'} eq 'delete');
    ok($content->{'node'}->{'dir'} eq $JSON::true);
    ok($content->{'node'}->{'key'} eq '/myTestDir');
}
