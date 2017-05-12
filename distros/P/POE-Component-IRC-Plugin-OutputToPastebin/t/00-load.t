#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('Carp');
    use_ok('POE::Component::IRC::Plugin');
    use_ok('POE');
    use_ok('POE::Component::WWW::Pastebin::Bot::Pastebot::Create');
	use_ok( 'POE::Component::IRC::Plugin::OutputToPastebin' );
}

diag( "Testing POE::Component::IRC::Plugin::OutputToPastebin $POE::Component::IRC::Plugin::OutputToPastebin::VERSION, Perl $], $^X" );
