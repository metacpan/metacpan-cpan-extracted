=pod

=head1 NAME

t/tcp.t - Net::Prober test suite

=head1 DESCRIPTION

Try to probe localhost via TCP/UDP connections.
It doesn't matter if it succeeds or not.
Some ports might be closed.

=cut

use strict;
use warnings;

use Test::More tests => 6;
use Net::Prober;

my $result = Net::Prober::probe_tcp({
    proto   => 'tcp',
    port    => '22',
    host    => 'localhost',
    timeout => 0.5,
});

ok($result && ref $result eq 'HASH', 'probe_tcp() returns a hashref');
ok(exists $result->{ok} && $result->{ok} =~ m{^[01]$},
    "TCP probe result: '$result->{ok}'"
);

ok(exists $result->{time}
    && $result->{time} > 0.0
    && $result->{time} <= 1.0,
    "Got an elapsed time too ($result->{time}s)",
);

$result = Net::Prober::probe_tcp({
    proto   => 'udp',
    port    => 'echo',
    host    => 'localhost',
    timeout => 0.5,
});

ok($result && ref $result eq 'HASH', 'probe_tcp() returns a hashref');
ok(exists $result->{ok} && $result->{ok} =~ m{^[01]$},
    "UDP probe result: '$result->{ok}'"
);

ok(exists $result->{time}
    && $result->{time} > 0.0
    && $result->{time} <= 1.0,
    "Got an elapsed time too ($result->{time}s)",
);
