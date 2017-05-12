use strict;
use warnings;

use Test::More;

BEGIN {
    push @LWP::Protocol::http::EXTRA_SOCK_OPTS, MaxLineLength => 1024;

    use_ok('Net::Google::DataAPI::Role::Service');
}

ok my %opts = @LWP::Protocol::http::EXTRA_SOCK_OPTS;
is $opts{MaxLineLength}, 1024;

done_testing;
