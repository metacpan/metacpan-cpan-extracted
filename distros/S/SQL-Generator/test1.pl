# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2001 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

use strict;

use vars qw($AUTOLOAD);

our $sql;

BEGIN
{
	use SQL::Generator;

	$sql = new SQL::Generator(

		lang => 'MYSQL',

		#post => "",

		historysize => 50,

		#autoprint => 1,

		prettyprint => 0

		) or die 'object construction failed';

	use subs qw( DEFAULT CREATE USE DROP DESCRIBE INSERT REPLACE SELECT );
}

END
{
	$sql->close();
}

sub AUTOLOAD
{
	my $func = $AUTOLOAD;

	$func =~ s/.*:://;

    	return if $func eq 'DESTROY';

		if( my %args = @_ )
		{
			$sql->$func( %args );
		}
		else
		{
			$sql->$func();
		}
}

## SQL PERLSCRIPT STARTS HERE ##

my $table = 'sql_generator_table';

my $database = 'sql_generator_db';

my %types =
(
	row1 => 'VARCHAR(10) AUTO_INCREMENT NOT NULL',

	row2 => 'INTEGER',

	row3 => 'VARCHAR(20)'
);

my %columns = ( row1 => '1', row2 => '2', row3 => '3' );

my %alias = ( row1 => 'Name', row2 => 'Age', row3 => 'SocialID' );

	#DEFAULT DATABASE => $database, TABLE => $table;

	CREATE DATABASE => $database;

	USE DATABASE => $database;

	CREATE TABLE => $table, COLS => \%types, PRIMARYKEY => 'row1';

	DESCRIBE TABLE => $table;

	INSERT

		COLS => [ keys %columns ],

		VALUES => [ values %columns ],

		INTO => $table;

	INSERT

		COLS => [ qw/row1 row2 row3/ ],

		VALUES => [ '1', '2', '3' ],

		INTO => $table;

	foreach (keys %columns)	{ $columns{$_}++ }

	INSERT

		SET => \%columns ,

		INTO => $table;

	foreach (keys %columns)	{ $columns{$_}++ }

	REPLACE

		COLS => [ keys %columns ],

		VALUES => [ values %columns ],

		INTO => $table;

	SELECT ROWS => '*', FROM => $table;

	SELECT ROWS => '*', FROM => $table, WITH => 'alpha', AS => [ SELECT ROWS => 'firstrow', FROM => 'othertable', WHERE => 'secondrow eq 10' ];

	SELECT ROWS => [ keys %types ], FROM => $table;

	SELECT ROWS =>  \%alias, FROM => $table, WHERE => 'row1 = 1 AND row3 = 3';

	DROP TABLE => $table;

	DROP DATABASE => $database;

	# provocate an errormsg

	DESCRIBE TABLE => $table;

	print "\nListing History with ", scalar @{ history() }, " entries of ", historysize(), " maximum\n";

	dump_history( undef, ";\n");
