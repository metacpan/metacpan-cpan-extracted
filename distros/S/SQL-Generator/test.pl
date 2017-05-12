#
# Distribution:	SQL::Generator
#
# Author:	Murat Uenalan (muenalan@cpan.org)
#
# Copyright:	Copyright (c) 1997 Murat Uenalan. All rights reserved.
#
# Note:		This program is free software; you can redistribute it and/or modify it
#
#		under the same terms as Perl itself.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;

use vars qw($AUTOLOAD);

use Carp;

use SQL::Generator;

my $loaded = 0;

my $lasttest;

BEGIN { $lasttest=2 }

BEGIN { $| = 1; print "1..$lasttest\n"; }

END {print "not ok $lasttest\n" unless $loaded;}

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $table = 'sql_generator_table';

my $database = 'sql_generator_db';

my %types =
(
	row1 => 'VARCHAR(10) NOT NULL AUTO_INCREMENT',

	row2 => 'INTEGER',

	row3 => 'VARCHAR(20)'
);

my %columns = ( row1 => '1', row2 => '2', row3 => '3' );

my %alias = ( row1 => 'Name', row2 => 'Age', row3 => 'SocialID' );

	my $sql = new SQL::Generator(

		lang => 'MYSQL',

		post => ";\n",

		autoprint => 0,

		prettyprint => 0,

		#FILE => '>out.sql',

	) or print 'not ';

	#die "HERE...";


printf "ok %d\n", ++$loaded;

	$sql->CREATE( DATABASE => $database );

	$sql->USE( DATABASE => $database );

	$sql->CREATE( TABLE => $table, COLS => \%types, PRIMARYKEY => 'row1' );

	$sql->DESCRIBE( TABLE => $table );

	$sql->INSERT(

		COLS => [ keys %columns ],

		VALUES => [ values %columns ],

		INTO => $table

		);

	foreach (keys %columns)	{ $columns{$_}++ }

	$sql->INSERT( SET => \%columns ,INTO => $table );

	foreach (keys %columns)	{ $columns{$_}++ }

	$sql->REPLACE(

		COLS => [ keys %columns ],

		VALUES => [ values %columns ],

		INTO => $table,

		);

	$sql->SELECT( ROWS => '*', FROM => $table );

	$sql->SELECT( ROWS => [ keys %types ], FROM => $table );

	$sql->SELECT(

		ROWS =>  \%alias,

		FROM => $table,

		WHERE => 'row1 = 1 AND row3 = 3'

		);

	$sql->DROP( TABLE => $table );

	$sql->DROP( DATABASE => $database );

	# evocate an errormsg

	$sql->DESCRIBE( TABLE => $table );

	printf "\nListing History with %d entries of %d maximum\n\n", scalar @{ $sql->history() }, $sql->historysize();

	$sql->dump_history();

	$sql->close();

printf "ok %d\n", ++$loaded;
