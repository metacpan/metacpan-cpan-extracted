=pod

=head1 NAME

t/smtp.t - Net::Prober test suite

=head1 DESCRIPTION

Try to probe a SMTP server

=cut

use strict;
use warnings;

use LWP::Online ':skip_all';
use Test::More tests => 4;

use Net::Prober;

my $result = Net::Prober::probe_smtp({
    host => 'smtp.gmail.com',
    port => 587,
    ssl  => 0,
    timeout => 10.0,
});

ok($result && ref $result eq 'HASH', 'probe_smtp() returns a hashref');
ok(exists $result->{ok} && $result->{ok}, 'Connected successfully to SMTP server');
ok(exists $result->{time}
    && $result->{time} > 0.0
    && $result->{time} <= 10.0,
    "Got an elapsed time too ($result->{time}s)",
);
ok(exists $result->{banner},
    "Got banner from server ($result->{banner})"
);

