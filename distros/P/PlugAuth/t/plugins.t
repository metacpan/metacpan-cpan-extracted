use strict;
use warnings;
use Test::Clustericious::Log;
use Test::More tests => 1;
use PlugAuth;

my $plug_auth = PlugAuth->new;
isa_ok $plug_auth->plugin('plug_auth'), 'Clustericious::Plugin::SelfPlugAuth';
