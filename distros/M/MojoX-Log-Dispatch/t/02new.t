#!perl -T
use warnings;
use strict;

use Test::More tests => 2;
use MojoX::Log::Dispatch;

#test1
my $mojo_log_dispatch = MojoX::Log::Dispatch->new();
ok( $mojo_log_dispatch && ref($mojo_log_dispatch) eq 'MojoX::Log::Dispatch',  'new() works' );
my $log_dispatch_obj = $mojo_log_dispatch->handle;
ok( $log_dispatch_obj  && ref($log_dispatch_obj) eq 'Log::Dispatch',  'handle() works, return Log::Dispatch');



