#!perl

use Test::More tests => 18;

BEGIN { use_ok( 'Task::Catalyst::Tutorial' ) }
BEGIN { use_ok( 'Catalyst::Runtime' ) }
BEGIN { use_ok( 'Catalyst::Devel' ) }
BEGIN { use_ok( 'Catalyst::Plugin::Authentication' ) }
BEGIN { use_ok( 'Catalyst::Authentication::Store::DBIx::Class' ) }
BEGIN { use_ok( 'Catalyst::Plugin::Authorization::ACL' ) }
BEGIN { use_ok( 'Catalyst::Plugin::Authorization::Roles' ) }
BEGIN { use_ok( 'Catalyst::Plugin::ConfigLoader' ) }
BEGIN { use_ok( 'Catalyst::Controller::HTML::FormFu' ) }
BEGIN { use_ok( 'Catalyst::Plugin::Session' ) }
BEGIN { use_ok( 'Catalyst::Plugin::Session::State::Cookie' ) }
BEGIN { use_ok( 'Catalyst::Plugin::Session::Store::FastMmap' ) }
BEGIN { use_ok( 'Catalyst::Plugin::StackTrace' ) } 
BEGIN { use_ok( 'Catalyst::Plugin::Static::Simple' ) } 
BEGIN { use_ok( 'DBIx::Class' ) } 
BEGIN { use_ok( 'DBIx::Class::Schema' ) } 
BEGIN { use_ok( 'Catalyst::View::TT' ) } 
BEGIN { use_ok( 'Catalyst::Model::DBIC::Schema' ) }

diag( "Testing Task::Catalyst::Tutorial $Task::Catalyst::Tutorial::VERSION, Perl $], $^X" );
