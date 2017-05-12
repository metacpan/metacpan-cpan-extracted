use strict;
use warnings;
use utf8;

use Test::More;
use HTTP::Tiny;
use Net::Airbrake;
use Data::Dumper;

plan skip_all => 'Require AIRBRAKE_API_KEY and AIRBRAKE_PROJECT_ID env'
    unless $ENV{AIRBRAKE_API_KEY} && $ENV{AIRBRAKE_PROJECT_ID};

my $airbrake = Net::Airbrake->new(
    api_key     => $ENV{AIRBRAKE_API_KEY},
    project_id  => $ENV{AIRBRAKE_PROJECT_ID},
    environment => 'Author Test',
);
my $res = $airbrake->notify({
    type      => ref $airbrake,
    message   => 'This is a test',
    backtrace => [
        { file => __FILE__, line => __LINE__, function => 'notify()' },
    ],
});
ok $res && $res->{id} && $res->{url};
warn Dumper($res);

## usually, creating located URL pointed by $res->{url} delays.
sleep 5;

## when the error report is created, airbrake.io returns 302 on that result url.
my $err = HTTP::Tiny->new(max_redirect => 0)->get($res->{url});
ok $err->{success};
is($err->{status}, 302) or warn $res->{content};

done_testing;
