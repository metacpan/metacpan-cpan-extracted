#!/usr/bin/env perl

use Test::More tests => 6;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('WWW::OhNoRobotCom::Search');
    use_ok('POE::Component::NonBlockingWrapper::Base');
	use_ok( 'POE::Component::WWW::OhNoRobotCom::Search' );
}

diag( "Testing POE::Component::WWW::OhNoRobotCom::Search $POE::Component::WWW::OhNoRobotCom::Search::VERSION, Perl $], $^X" );
can_ok('POE::Component::WWW::OhNoRobotCom::Search', qw(spawn search
_methods_define _prepare_wheel _check_args  _process_request  _wheel_entry));