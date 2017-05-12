use strict;
use warnings;

use Test::More;
use Test::Exception;

use Net::Domain qw/ hostfqdn /;
use String::Random;

BEGIN { use_ok 'Riemann::Client'; }

SKIP: {
    skip '$ENV{RIEMANN_SERVER} not defined', 9
        unless defined $ENV{RIEMANN_SERVER};

    my $rand = String::Random->new;

    my $r = Riemann::Client->new(
        host => $ENV{RIEMANN_SERVER},
        port => $ENV{RIEMANN_SERVER_PORT} || 5555,
    );

    my %msg = (
        service => $rand->randpattern('cCcnCnc'),
        metric  => rand(10),
        state   => 'ok',
        description => 'a',
    );


    ok ($r->send(\%msg), "Message sent over tcp");

    my $res = $r->query('host = "' . hostfqdn() . '"');
    ok($res->{ok}, "Query is ok");
    is(ref $res->{events}, 'ARRAY', "Got an array as query response");
    is(ref $res->{events}->[0], 'Event', "Array of events");

    my %msg2 = (
        service => $rand->randpattern('cCcnCnc'),
        metric  => rand(10),
        state   => 'warn',
        description => 'b',
    );
    my %msg3 = (
        service => $rand->randpattern('cCcnCnc'),
        metric  => rand(10),
        state   => 'crit',
        description => 'c',
    );

    ok($r->send(\%msg2, \%msg3), 'Send multiple messages at once');

    undef $r;

    my $rudp = Riemann::Client->new(
        host => $ENV{RIEMANN_SERVER},
        port => $ENV{RIEMANN_SERVER_PORT} || 5555,
        proto => 'udp',
    );

    ok ($rudp->send(\%msg), "Message sent over udp");

    # Make the message too bit to send over UDP
    $msg{description} = 'a' x 20000;
    dies_ok { $rudp->send(\%msg) } "Send dies with message too long";

    $res = $rudp->query('host = "' . hostfqdn() . '"');
    ok($res->{ok}, "Queries still working");
    is(ref $res->{events}, 'ARRAY', "Got an array as query response");
    is(ref $res->{events}->[0], 'Event', "Array of events");
}

done_testing();
