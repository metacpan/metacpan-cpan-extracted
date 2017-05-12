#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Filter::Line');
    use_ok('POE::Filter::Reference');
    use_ok('POE::Wheel::Run');
    use_ok( 'POE::Component::NonBlockingWrapper::Base' );
}

diag( "Testing POE::Component::NonBlockingWrapper::Base $POE::Component::NonBlockingWrapper::Base::VERSION, Perl $], $^X" );

can_ok('POE::Component::NonBlockingWrapper::Base', qw(
    spawn
                        _child_error
                    _child_closed
                    _child_stdout
                    _child_stderr
                    _sig_child
                    _start
    shutdown
    _shutdown
    _methods_define
    session_id
    _wheel_entry
    _wheel
    _process_request
    _check_args
));