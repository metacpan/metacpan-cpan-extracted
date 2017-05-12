use strict;
use warnings;
use utf8;

use Test::More;
use HTTP::Tiny;
use Net::Airbrake::V2;

plan skip_all => 'Env vars AIRBRAKE_API_KEY and AIRBRAKE_URL must be set'
  unless $ENV{AIRBRAKE_API_KEY} && $ENV{AIRBRAKE_URL};

my $airbrake = Net::Airbrake::V2->new(
  base_url    => $ENV{AIRBRAKE_URL},
  api_key     => $ENV{AIRBRAKE_API_KEY},
  environment => 'Author Test',
);

my $res = $airbrake->notify(
  {
    type      => ref $airbrake,
    message   => 'This is a test',
    backtrace => [
        { file => __FILE__, line => __LINE__, function => 'notify()' },
    ],
  },
  {
    params => {
      heart => "❤",
      tree => {
        leaf => [0, 1, "two", { three => undef }],
      },
    }
  }
);

ok $res && $res->{id} && $res->{url};
diag explain $res;

# Usually, creating located URL pointed by $res->{url} delays.
sleep 5;

# When the error report is created, airbrake.io returns 302 on that result url.
my $err = HTTP::Tiny->new(max_redirect => 0)->get($res->{url});
is($err->{status}, 302) or diag explain $res->{content};

done_testing;
