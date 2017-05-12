package TinySubPlug;
use strict;
use warnings;
use Moo;
#has 'plugin_system' => (is => 'ro', isa => 'Plugin::Tiny', required => 1);

sub do_something {
    'a plugin that is loaded by another plugin';
}


1;
