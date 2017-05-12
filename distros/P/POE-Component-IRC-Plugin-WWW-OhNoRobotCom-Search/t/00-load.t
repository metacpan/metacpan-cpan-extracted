#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('POE::Component::WWW::OhNoRobotCom::Search');
    use_ok('POE::Component::IRC::Plugin::BasePoCoWrap');
	use_ok( 'POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search' );
}

diag( "Testing POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search $POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search::VERSION, Perl $], $^X" );
