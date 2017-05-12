#!perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::App::Cmd::Command::BashComplete' );
}

diag( "Testing MooseX::App::Cmd::Command::BashComplete $MooseX::App::Cmd::Command::BashComplete::VERSION, Perl $], $^X" );
