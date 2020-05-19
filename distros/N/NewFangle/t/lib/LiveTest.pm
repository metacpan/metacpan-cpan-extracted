package LiveTest;

use strict;
use warnings;
use NewFangle qw( newrelic_configure_log newrelic_init );
use Test2::V0 qw( skip_all );

sub import
{
  skip_all 'enable tests by running newrelic-daemon and setting PERL_NEWRELIC_LIVE_TESTS'
    unless $ENV{PERL_NEWRELIC_LIVE_TESTS};
  newrelic_configure_log("./newrelic_sdk.log", "debug");
  newrelic_init(undef, 300000);
}

1;
