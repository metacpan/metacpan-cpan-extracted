#!/usr/bin/perl

use warnings;
use Test::Builder::Tester;
use Test::More;
use Term::Menus::FromFile qw(pick_from_filename pick_from_file);

plan tests => 6;

SKIP: {
 	eval { require Test::Builder::Tester };
	skip "Test::Builder::Tester is needed for tests to run.", 6 if $@;
	Test::Builder::Tester->import();
################
#
# Warning!  Black Magic ahead!
#
################

test_out();		# Without a terminal, Term::Menus outputs a newline...

my $out = \STDOUT;	# Take a copy of STDOUT

# Open STDIN for writing.
# Forks a child to read STDIN.
my $pid = open(KID, "|-");

# If we are the parent, print commands for the kid.
if ($pid) {
	print KID "1\n2\nq\n";
}
# if we are the kid, have some fun...
else {
	# Close _our_ STDOUT, and (re?)open our parent's...
	close STDOUT;
	open STDOUT, '>', $out;
	
	# Hey, we're acutally doing a menu.
	my $result = pick_from_filename('test_data/menu1');
	
	# Check the output is as expected.
	test_test('Basic Menu output.');
	is($result, 'Item 1', 'Result 1 test.');
	
	# Set up another test.
	test_out();
	
	open my $menu_file, '<', 'test_data/menu1';
	$result = pick_from_file($menu_file);
	close $menu_file;
	
	# Check the output is as expected.
	test_test('Basic Menu output 2.');
	is($result, 'Item 2', 'Result 2 test.');

	# Set up a third test.
	test_out();
	
	open $menu_file, '<', 'test_data/menu1';
	$result = pick_from_file($menu_file);
	close $menu_file;
	
	# Check the output is as expected.
	test_test('Basic Menu output 3.');
	is($result, ']quit[', 'Result quit test.');

	# Exit the kid.
	exit;
}

} # Close skip block.
