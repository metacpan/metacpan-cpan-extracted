#!perl -T

use Test::More ;

my @modules = qw( 
    Supervisor
    Supervisor::Base 
    Supervisor::Class 
    Supervisor::Constants
    Supervisor::Controller 
    Supervisor::Log
    Supervisor::ProcessFactory 
    Supervisor::Process
    Supervisor::Session 
    Supervisor::Utils 
    Supervisor::RPC::Server 
    Supervisor::RPC::Client
);

plan(tests => scalar(@modules));
use_ok($_) for @modules;

diag( "Testing Supervisor $Supervisor::VERSION, Perl $], $^X" );
