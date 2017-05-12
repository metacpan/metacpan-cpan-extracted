#!perl -T

use Test::More tests => 1;
use Class::Trigger;
use Sledge::Pages::Base;

BEGIN {
    use_ok( 'Sledge::Plugin::BeforeOutput' );
}

diag( "Testing Sledge::Plugin::BeforeOutput $Sledge::Plugin::BeforeOutput::VERSION, Perl $], $^X" );
