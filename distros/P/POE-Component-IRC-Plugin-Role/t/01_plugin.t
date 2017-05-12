package Plugin;

use Moose;

with 'POE::Component::IRC::Plugin::Role';

no Moose;

package main;

use Test::More tests => 1;

my $plugin = Plugin->new();

isa_ok( $plugin, 'Plugin', 'It is a plugin' );
