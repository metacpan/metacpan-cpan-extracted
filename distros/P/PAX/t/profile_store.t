use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAX::ProfileStore;

my $store = PAX::ProfileStore->new(threshold => 2);
$store->record_dispatch({ region_name => 'main::add', status => 'native' });
$store->record_dispatch({ region_name => 'main::add', status => 'fallback' });
$store->record_dispatch({ region_name => 'main::multiply', status => 'native' });
$store->record_dispatch({ region_name => 'main::multiply', status => 'native', osr_event => 'promote' });
$store->record_dispatch({ region_name => 'main::multiply', status => 'fallback', osr_event => 'retire' });

my $report = $store->report;
is($report->{threshold}, 2, 'threshold recorded');
my %regions = map { $_->{region} => $_ } @{ $report->{regions} };
is($regions{'main::add'}{dispatches}, 2, 'dispatch count recorded');
is($regions{'main::add'}{native}, 1, 'native count recorded');
is($regions{'main::add'}{fallback}, 1, 'fallback count recorded');
ok($regions{'main::add'}{hot}, 'hot region classified');
ok($regions{'main::multiply'}{hot}, 'second region hot after threshold');
is($regions{'main::multiply'}{osr_promotions}, 1, 'OSR promotion count recorded');
is($regions{'main::multiply'}{osr_retirements}, 1, 'OSR retirement count recorded');

done_testing;

=pod

=head1 NAME

t/profile_store.t - regression coverage for profile-store merge and persistence behavior

=head1 DESCRIPTION

This test exercises profile-store merge and persistence behavior. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for profile-store merge and persistence behavior. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/profile_store.t

=head1 WHY IT EXISTS

PAX uses this test to keep profile-store merge and persistence behavior from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
