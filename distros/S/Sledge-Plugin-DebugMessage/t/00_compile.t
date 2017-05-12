use strict;
use warnings;
use Test::More tests => 1;

sub register_hook { 'dummy' }
BEGIN { use_ok 'Sledge::Plugin::DebugMessage' }
