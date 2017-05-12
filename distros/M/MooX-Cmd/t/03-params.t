#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use MooX::Cmd::Tester;

use FindBin qw($Bin);
use lib "$Bin/lib";

use FirstTestApp;
use SecondTestApp;
use ThirdTestApp;

{
	local @ARGV;
	my $cmd = SecondTestApp->new_with_cmd(command_execute_method_name => "run");
	my $rv = test_cmd_ok( $cmd, [] );
	my @execute_return = @{$rv->execute_rv};
	is_deeply(\@execute_return,[$cmd],'Checking result of "SecondTestApp(command_base => "SecondTestApp::Cmd") => []"');
}

{
	local @ARGV;
	my $cmd = SecondTestApp->new_with_cmd(command_base => "SecondTestApp::Cmd");
	my $rv = test_cmd_ok( $cmd, [] );
	my @execute_return = @{$rv->execute_rv};
	is_deeply(\@execute_return,[$cmd],'Checking result of "SecondTestApp(command_base => "SecondTestApp::Cmd") => []"');
}

{
	local @ARGV;
	my $cmd = SecondTestApp->new_with_cmd(command_creation_chain_methods => "new");
	my $rv = test_cmd_ok( $cmd, [] );
	my @execute_return = @{$rv->execute_rv};
	is_deeply(\@execute_return,[$cmd],'Checking result of "SecondTestApp(command_creation_chain_methods => "new") => []"');
}

{
	local @ARGV;
	my $cmd = SecondTestApp->new_with_cmd(command_commands => {ifc => "SecondTestApp::Cmd::ifc", cwo => "SecondTestApp::Cmd::cwo"});
	my $rv = test_cmd_ok( $cmd, [] );
	my @execute_return = @{$rv->execute_rv};
	is_deeply(\@execute_return,[$cmd],'Checking result of "SecondTestApp(command_commands => {ifc => "SecondTestApp::Cmd::ifc", cwo => "SecondTestApp::Cmd::cwo"}) => []"');
}

{
	local @ARGV;
	my $cmd = SecondTestApp->new_with_cmd(command_base => "SecondTestApp::Cmd", command_creation_chain_methods => "new");
	my $rv = test_cmd_ok( $cmd, [] );
	my @execute_return = @{$rv->execute_rv};
	is_deeply(\@execute_return,[$cmd],'Checking result of "SecondTestApp(command_base => "SecondTestApp::Cmd") => []"');
}

{
	local @ARGV = qw(foo);
	my $cmd = ThirdTestApp->new_with_cmd(command_execute_from_new => undef);
	my $rv = test_cmd_ok( $cmd, [qw(foo)] );
	is($rv->execute_rv,undef,'Checking result of "ThirdTestApp(command_execute_from_new => undef) => []"');
}

{
	local @ARGV = qw(foo);
	my $cmd = ThirdTestApp->new_with_cmd(command_execute_from_new => 0);
	my $rv = test_cmd_ok( $cmd, [qw(foo)] );
	is_deeply($rv->execute_rv,undef,'Checking result of "ThirdTestApp(command_execute_from_new => 0) => []"');
}

{
	local @ARGV;
	my $cmd = SecondTestApp->new_with_cmd(command_execute_return_method_name => "was_haste");
	my $rv = test_cmd_ok( $cmd, [] );
	my @execute_return = @{$rv->execute_rv};
	is_deeply(\@execute_return,[$cmd],'Checking result of "SecondTestApp(command_execute_return_method_name => "was_haste") => []"');
}

{
	local @ARGV;
	eval {
	    my $cmd = SecondTestApp->new_with_cmd(command_creation_chain_methods => "search_me");
	};
	like( $@, qr/Can't find a creation method on/, 'Load fails for SecondTestApp(command_creation_chain_methods => "search_me") => []' );
}

SKIP: {
	eval "use OptionTestApp;";
	$@ and skip("MooX::Options required", 1);
	local @ARGV = qw(oops);
	my $cmd = eval {
	    OptionTestApp->new_with_cmd(command_creation_chain_methods => "new_with_options");
	};
	like( $@, qr/Can't find a creation method on/, 'Load fails for OptionTestApp(command_creation_chain_methods => "new_with_options") => []' );
}

done_testing;
