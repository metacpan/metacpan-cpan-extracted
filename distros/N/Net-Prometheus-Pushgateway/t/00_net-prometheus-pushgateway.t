use strict;
use warnings;
use lib 'lib';
use Test::More 'no_plan';
use File::Spec;

BEGIN {
    use_ok("Net::Prometheus::Pushgateway");
}

can_ok("Net::Prometheus::Pushgateway", "new");

