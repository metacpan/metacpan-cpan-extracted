use strict;
use Test::More ;

my @modules = qw(Spread::Messaging 
                 Spread::Messaging::Transport
                 Spread::Messaging::Content);

plan(tests => scalar(@modules));

use_ok($_) for @modules;
