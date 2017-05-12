#!/usr/bin/perl

# Tests the logic for extracting the list of functions in a Java program

use strict;
use warnings;
use Test::More;

plan( tests => 6 );

use Parse::Functions::Java ();

# Sample code we will be parsing
my $code = <<'END_JAVA';
/**
public static void bogus(a, b) {
}
*/
/*
public static void bogus(a, b) {
}
*/
//public static void bogus(a, b) {

//
public static void bogus(a, b) {
// ticket #1351

public static void main(String args[]) {
}

public abstract void myAbstractMethod();

public byte[] toByteArray();

public static <T> T[] genericToArray(T... elements) {
   return elements;
}

public abstract List<Integer> getList();

private int subtract(int a, int b) {
	return a - b;
}

private int add(int a, int b) {
	return a + b;
}  
END_JAVA

######################################################################
# Basic Parsing

SCOPE: {

	# Create the function list parser
	my $lf = new_ok(
		'Parse::Functions::Java'
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find( $code ) ],
		[   qw{
				main
				myAbstractMethod
				toByteArray
				genericToArray
				getList
				subtract
				add
				}
		],
		'Found expected functions',
	);
}





######################################################################
# Alphabetical Ordering

SCOPE: {

	# Create the function list parser
	my $lf = new_ok(
		'Parse::Functions::Java'
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find( $code, 'alphabetical' ) ],
		[   qw{
				add
				genericToArray
				getList
				main
				myAbstractMethod
				subtract
				toByteArray
				}
		],
		'Found expected functions (alphabetical)',
	);
}





######################################################################
# Alphabetical Ordering (Private Last)

SCOPE: {

	# Create the function list parser
	my $lf = new_ok(
		'Parse::Functions::Java'
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find( $code, 'alphabetical_private_last' ) ],
		[   qw{
				add
				genericToArray
				getList
				main
				myAbstractMethod
				subtract
				toByteArray
				}
		],
		'Found expected functions (alphabetical_private_last)',
	);
}
