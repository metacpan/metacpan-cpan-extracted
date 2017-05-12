=pod

=head1 NAME

t/imap.t - Net::Prober test suite

=head1 DESCRIPTION

Try to probe a IMAP server

=cut

use strict;
use warnings;

use LWP::Online ':skip_all';
#use Test::More tests => 4;
use Test::More skip_all => "Need a stable IMAP server to connect to and SSL doesn't work";

use Net::Prober;

my $result = Net::Prober::probe_imap({
    host    => 'imap.gmail.com',
    port    => 993,
    ssl     => 1,
    timeout => 10.0,
});

ok($result && ref $result eq 'HASH', 'probe_imap() returns a hashref');
ok(exists $result->{ok} && $result->{ok}, 'Connected successfully to IMAP server');
ok(exists $result->{time}
    && $result->{time} > 0.0
    && $result->{time} <= 10.0,
    "Got an elapsed time too ($result->{time}s)",
);
ok(exists $result->{banner} && defined $result->{banner},
    "Got a IMAP banner ($result->{banner})"
);
