#/usr/bin/perl -w
use strict;
use Test::More;
use Config;
package test; ## no critic
use Moo;
use MooX::Options;
with qw(MooX::Ipc::Cmd);
1;


package main; ## no critic
# use Log::Any::Adapter('Stdout');
use constant NO_SUCH_CMD => "this_command_had_better_not_exist";

# We want to invoke our sub-commands using Perl.

my $perl_path = $Config{perlpath};

if ($^O ne 'VMS') {
	$perl_path .= $Config{_exe}
		unless $perl_path =~ m/$Config{_exe}$/i;
}

# Win32 systems don't support multi-arg pipes.  Our
# simple captures will begin with single-arg tests.
my @output_exe = "$perl_path output.pl";

# use_ok("IPC::System::Simple","capture");
my $test=test->new;
chdir("t");

# Scalar capture

my @output = $test->_capture([@output_exe]);
ok(1);

is_deeply(\@output,["Hello\n","Goodbye\n"],"Scalar capture");
is($/,"\n","IFS intact");

my $qx_output = qx(@output_exe);
# is_deeply(\@output, $qx_output, "capture and qx() return same results");

# List capture

@output = $test->_capture([@output_exe]);

is_deeply(\@output,["Hello\n", "Goodbye\n"],"List capture");
is($/,"\n","IFS intact");

my $no_output;
eval {
	$no_output = $test->_capture([NO_SUCH_CMD]);
};

is($@->exit_status,-1, "failed capture");
is($no_output,undef, "No output from failed command");

# The following is to try and catch weird buffering issues
# as we move around filehandles inside capture().

print "# buffer test string";	# NB, no trailing newline

@output = $test->_capture([@output_exe]);

print "\n";  # Terminates our test string above in TAP output

is_deeply(\@output,["Hello\n","Goodbye\n"],"Single-arg capture still works");
done_testing;
1;
