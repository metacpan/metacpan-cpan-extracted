#!/usr/bin/perl -w
use strict;
use Config;
use Test::More;
package test;
use Moo;
use MooX::Options;
with qw(MooX::Ipc::Cmd);
1;
package main;
use constant NO_SUCH_CMD => "this_command_had_better_not_exist_either";
use constant NOT_AN_EXE  => "not_an_exe.txt";
use List::Util qw(any);;
my $test=test->new;
plan tests => 13;

# We want to invoke our sub-commands using Perl.

my $perl_path = $Config{perlpath};

if ($^O ne 'VMS') {
	$perl_path .= $Config{_exe}
		unless $perl_path =~ m/$Config{_exe}$/i;
}

# use_ok("IPC::System::Simple","capture");
chdir("t");

# The tests below for $/ are left in, even though IPC::System::Simple
# never touches $/

# Scalar capture

my $output = $test->_capture([$perl_path,"output.pl",0]);
ok(1);

is_deeply($output,["Hello\n","Goodbye\n"],"Scalar capture");
is($/,"\n",'$/ intact');

# List capture

my @output = $test->_capture([$perl_path,"output.pl",0]);
ok(1);

is_deeply(\@output,["Hello\n", "Goodbye\n"],"List capture");
is($/,"\n",'$/ intact');

# List capture with odd $/

{
	local $/ = "e";
	my @odd_output = $test->_capture([$perl_path,"output.pl",0]);
	ok(1);

	is_deeply(\@odd_output,["He","llo\nGoodbye","\n"], 'Odd $/ capture');

}

my $no_output;
eval {
        $no_output = $test->_capture([NO_SUCH_CMD,1]);
};

is($@->exit_status,-1, "failed capture");
is($no_output,undef, "No output from failed command");

# Running Perl -v

my $perl_output = $test->_capture([$perl_path,"-v"]);
ok(any {/Larry Wall/} @$perl_output,  "perl -v contains Larry");

SKIP: {

	# Considering making these tests depend upon the OS,
	# as well as $ENV{AUTHOR_TEST}, since different systems
	# will have different ways of expressing their displeasure
	# at executing a file that's not executable.

	skip('Author test.  Set $ENV{TEST_AUTHOR} to true to run', 2)
		unless $ENV{TEST_AUTHOR};

	chmod(0,NOT_AN_EXE);
	eval { capture(NOT_AN_EXE,1); };
        chmod(0644,NOT_AN_EXE);             # To stop git complaining

	like($@, qr{Permission denied|No such file|The system cannot find the file specified}, "Permission denied on non-exe" );
	like($@, qr{failed to start}, "Non-exe failed to start" );

}
1;
