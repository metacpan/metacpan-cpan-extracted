use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Net::Google::DataAPI::Role::Service');
}

ok my %opts = @LWP::Protocol::http::EXTRA_SOCK_OPTS;
is $opts{MaxLineLength}, 1048576;

done_testing;
