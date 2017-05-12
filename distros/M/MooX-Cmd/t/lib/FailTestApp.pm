package FailTestApp;

use Moo;
use MooX::Cmd execute_from_new => undef;

around _build_command_execute_method_name => sub { "run" };

around _build_command_execute_from_new => sub { 0 };

sub run { @_ }

1;
