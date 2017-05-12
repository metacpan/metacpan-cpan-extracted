=pod

=head1 NAME

t/http.t - Net::Prober test suite

=head1 DESCRIPTION

Try to probe hosts via HTTP connections

=cut

use strict;
use warnings;

use Data::Dumper;
use LWP::Online ':skip_all';
use Test::More tests => 6;

use Net::Prober;

my $result = Net::Prober::probe_http({
    host    => 'sitecheck2.opera.com',
    url     => '/ping',
    match   => 'pong',
    timeout => 5.0,
});

ok($result && ref $result eq 'HASH', 'probe_http() returns a hashref');
ok(exists $result->{ok} && $result->{ok}, 'Page downloaded and MD5 verified');
ok(exists $result->{time}
    && $result->{time} > 0.0
    && $result->{time} <= 5.0,
    "Got an elapsed time too ($result->{time}s)",
);

$result = Net::Prober::probe({
    class   => 'http',
    host    => 'www.opera.com',
    url     => '/computer',
    match   => 'Opera',
    timeout => 10.0,
});

ok($result->{ok}) or diag($result->{reason});

my $t0 = time;

$result = Net::Prober::probe_http({
    host    => 'localhost',
    port    => 8433,
    url     => '/ping.html',
    timeout => 1.0,
    # Any result will be considered successful
    up_status_re => '^...$',
});

my $t1 = time;

ok(exists $result->{ok} && $result->{ok} == 1,
    "Result should be successful because of up_status_re")
    or diag($result->{reason});

ok(($t1 - $t0) <= 2,
    "Probe of unavailable service should honor timeout"
);
