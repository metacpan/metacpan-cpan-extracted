use strict;
use warnings;
use Test::More tests => 1;

sub add_trigger { };
BEGIN {
use_ok( 'Sledge::Plugin::Stash' );
}

diag( "Testing Sledge::Plugin::Stash $Sledge::Plugin::Stash::VERSION" );
