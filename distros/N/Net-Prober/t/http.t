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
use Test::More tests => 5;

use Net::Prober;

my $result = Net::Prober::probe_http({
    host    => 'www.google.com',
    url     => '/robots.txt',
    match   => 'Sitemap',
    timeout => 10.0,
});

ok($result && ref $result eq 'HASH', 'probe_http() returns a hashref');
ok(exists $result->{ok} && $result->{ok}, 'Page downloaded and MD5 verified')
    or diag($result->{reason});
ok(exists $result->{time}
    && $result->{time} > 0.0
    && $result->{time} <= 10.0,
    "Got an elapsed time too ($result->{time}s)",
);

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
