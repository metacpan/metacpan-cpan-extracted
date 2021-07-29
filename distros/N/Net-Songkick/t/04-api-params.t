use strict;
use warnings;

use Test::More;

use Net::Songkick;

my $ns = Net::Songkick->new({ api_key => 'dummy' });

my @param_tests = ({
  method => 'events_params',
  params => [qw[ artist_id artist_name artists location
                 max_date min_date type venue_id ]],
}, {
  method => 'user_events_params',
  params => [qw[ artist_id artist_name artists attendance
                 location max_date min_date type venue_id ]],
}, {
  method => 'user_gigs_params',
  params => [qw[ page per_page ]],
}, {
  method => 'artist_events_params',
  params => [qw[ min_date max_date page per_page order ]],
}, {
  method => 'venue_events_params',
  params => [qw[ page per_page ]],
}, {
  method => 'metro_events_params',
  params => [qw[ page per_page ]],
});

foreach my $test (@param_tests) {
  can_ok($ns, my $method = $test->{method});
  ok(my $params = $ns->$method, "Got params from $method");
  is_deeply([sort keys %$params], [ sort @{$test->{params}} ],
            "Params from $method are correct");
}

done_testing;
