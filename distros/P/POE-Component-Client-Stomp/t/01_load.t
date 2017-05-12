use strict;
use Test::More ;

my @modules = qw(POE::Component::Client::Stomp);

plan(tests => scalar(@modules));

use_ok($_) for @modules;
