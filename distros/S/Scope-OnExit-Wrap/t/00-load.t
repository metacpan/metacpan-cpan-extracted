#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 1;
 
BEGIN {
    use_ok( 'Scope::OnExit::Wrap' );
}
 
diag( "Testing Scope::OnExit::Wrap $Scope::OnExit::Wrap::VERSION ($Scope::OnExit::Wrap::_backend), Perl $], $^X" );
