use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Test::NFA qw(new_api);

# Make $calls API calls, spending $gap seconds on other work before each one,
# and check the resulting send times.
sub pacing_ok {
        my %arg = @_;

        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };

        my $api = new_api(latency => $arg{latency} || 0,
                          (defined $arg{per_hour} ? (api_calls_per_hour => $arg{per_hour}) : ()));

        my $start = $api->_now;

        for (1 .. $arg{calls}) {
                $api->advance($arg{gap}) if $arg{gap};
                $api->api_call({method => 'flickr.test.echo', args => {}});
        }

        my @sent    = map { $_ - $start } @{ $api->{api}->sent_at };
        my $elapsed = $sent[-1];

        local $Test::Builder::Level = $Test::Builder::Level + 1;

        subtest $arg{desc} => sub {
                is(@sent, $arg{calls}, "sent $arg{calls} requests");

                cmp_ok(max_in_window(\@sent, 3600), '<=', $arg{hourly_max},
                       "at most $arg{hourly_max} sent in any hour");

                cmp_ok($elapsed, '>=', $arg{elapsed}->[0], "took at least $arg{elapsed}->[0]s");
                cmp_ok($elapsed, '<=', $arg{elapsed}->[1], "took at most $arg{elapsed}->[1]s");

                if ($arg{warning}) {
                        like("@warnings", $arg{warning}, "warned about config");
                } else {
                        is("@warnings", "", "no warnings");
                }
        };
}

sub max_in_window {
        my ($times, $window) = @_;

        my ($max, $lo) = (0, 0);

        for my $hi (0 .. $#$times) {
                $lo ++ while $times->[$hi] - $times->[$lo] >= $window;
                my $n = $hi - $lo + 1;
                $max = $n if $n > $max;
        }

        return $max;
}

pacing_ok(desc       => "first ten calls go out at once",
          calls      => 10,
          hourly_max => 10,
          elapsed    => [0, 0]);

pacing_ok(desc       => "then about one per second",
          calls      => 20,
          hourly_max => 20,
          elapsed    => [10, 10.1]);

pacing_ok(desc       => "never more than 3600 in an hour",
          calls      => 8000,
          hourly_max => 3600,
          elapsed    => [8010, 8015]);

pacing_ok(desc       => "latency overlaps the pause",
          calls      => 1000,
          latency    => 0.4,
          hourly_max => 3600,
          elapsed    => [990, 1000]);

pacing_ok(desc       => "slow requests are not paced further",
          calls      => 100,
          latency    => 1.5,
          hourly_max => 3600,
          elapsed    => [148.5, 148.5]);

pacing_ok(desc       => "other work between calls counts toward the pause",
          calls      => 100,
          gap        => 0.75,
          latency    => 0.25,
          hourly_max => 3600,
          elapsed    => [99, 100.3]);

pacing_ok(desc       => "a lower rate can be configured",
          per_hour   => 1800,
          calls      => 4000,
          hourly_max => 1800,
          elapsed    => [7980, 8020]);

pacing_ok(desc       => "the rate is capped at Flickr's limit",
          per_hour   => 10000,
          calls      => 8000,
          hourly_max => 3600,
          elapsed    => [8010, 8015],
          warning    => qr/at most 3600/);

pacing_ok(desc       => "the rate has a floor",
          per_hour   => 1,
          calls      => 3,
          hourly_max => 3,
          elapsed    => [120, 124],
          warning    => qr/at least 60/);

done_testing;
