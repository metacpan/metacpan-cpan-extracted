#!/usr/bin/perl

use warnings;
use Test::Builder::Tester;
use Test::More;
use Term::Menus::FromFile qw(menu_from_filename pick_command_from_filename);

plan tests => 8;


SKIP: {
 	eval { require Test::Builder::Tester };
	skip "Test::Builder::Tester is needed for tests to run.", 8 if $@;
	Test::Builder::Tester->import();
################
#
# Warning!  Black Magic ahead!
#
################

test_out();		# Without a terminal, Term::Menus outputs a newline...

my $out = \STDOUT;	# Take a copy of STDOUT
my $err = \STDERR;

# Open STDIN for writing.
# Forks a child to read STDIN.
my $pid = open(KID, "|-");

# If we are the parent, print commands for the kid.
if ($pid) {
	print KID "1\n2\nq\n3\n";
}
# if we are the kid, have some fun...
else {
	# Close _our_ STDOUT, and (re?)open our parent's...
	close STDOUT;
	open STDOUT, '>', $out;
	
	# Same with STDERR.
	close STDERR;
	open STDERR, '>', $err;

	# Hey, we're acutally doing a menu.
	my $result = pick_command_from_filename('test_data/menu2');
	
	# Check the output is as expected.
	test_test('Command Menu output.');
	is($result, '', 'Advanced 1 test.');
	
	# Test 2.
	test_out();
	$result = pick_command_from_filename('test_data/menu2');
	
	# Check the output is as expected.
	test_test('Command Menu output 2.');
	is($result, "Hello, testers!\n", 'Advanced 2 test.');
	
	# Test 3.
	test_out();
	$result = pick_command_from_filename('test_data/menu2');
	
	# Check the output is as expected.
	test_test('Command Menu output 3.');
	is($result, ']quit[', 'Advanced quit test.');
	
	# Test 4.
	test_err(); # !?!?!!?  We should see _something_...
	test_out();
	$result = pick_command_from_filename('test_data/menu2');
	
	# Check the output is as expected.
	test_test('Command Menu output 4.');
	is($result, undef, 'Advanced bad script test.');

exit; # Close the kid.	
}

} # Close skip block.
