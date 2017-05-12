use strict;
use Test::More ;

my @modules = qw(POE::Filter::Stomp);

plan(tests => scalar(@modules));

use_ok($_) for @modules;