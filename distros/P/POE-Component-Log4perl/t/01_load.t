use strict;
use Test::More ;

my @modules = qw(POE::Component::Log4perl);

plan(tests => scalar(@modules));

use_ok($_) for @modules;
