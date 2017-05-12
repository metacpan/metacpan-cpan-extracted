#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Perl::Critic::Policy::CodeLayout::ProhibitSpaceIndentation' ) || print "Bail out!\n";
}

diag( "Testing Perl::Critic::Policy::CodeLayout::ProhibitSpaceIndentation $Perl::Critic::Policy::CodeLayout::ProhibitSpaceIndentation::VERSION, Perl $], $^X" );
