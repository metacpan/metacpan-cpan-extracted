use strict;
use warnings;
BEGIN {
  eval 'use Test::Clustericious::Log';
  eval 'use File::HomeDir::Test'
    unless $INC{'File/HomeDir/Test.pm'};
}
use Test::More tests => 2;
use PlugAuth;

my $app = PlugAuth->new;
isa_ok $app, 'PlugAuth';

my $auth_plugin = $app->plugin('plug_auth');
isa_ok $auth_plugin, 'Clustericious::Plugin::SelfPlugAuth';
