=pod

=head1 NAME

t/ssh.t - Net::Prober test suite

=head1 DESCRIPTION

Try to probe a SSH server

=cut

use strict;
use warnings;

use LWP::Online ':skip_all';
use Test::More tests => 7;

use Net::Prober;

my $result = Net::Prober::probe_ssh({
    host => 'sdf.org',
    timeout => 10.0,
});

ok($result && ref $result eq 'HASH', 'probe_ssh() returns a hashref');
ok(exists $result->{ok} && $result->{ok}, 'Connected successfully to SSH server');
ok(exists $result->{time}
    && $result->{time} > 0.0
    && $result->{time} <= 10.0,
    "Got an elapsed time too ($result->{time}s)",
);

# Dump ssh information we got from the banner
for (qw(banner protoversion softwareversion comments)) {
    ok(exists $result->{$_} && defined $result->{$_},
        "Got SSH $_ from banner ($result->{$_})"
    );
}
