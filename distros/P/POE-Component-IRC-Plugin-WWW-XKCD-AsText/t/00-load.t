#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::WWW::XKCD::AsText');
    use_ok('POE::Component::IRC::Plugin');
	use_ok('POE::Component::IRC::Plugin::WWW::XKCD::AsText');
}

diag( "Testing POE::Component::IRC::Plugin::WWW::XKCD::AsText $POE::Component::IRC::Plugin::WWW::XKCD::AsText::VERSION, Perl $], $^X" );
