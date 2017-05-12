BEGIN
{
	$| = 1; print "1..2\n";
}

my $loaded;

use strict;
use Carp;
use SQL::Generator;

my $table = 'sql_statement_construct_table';

my $database = 'sql_statement_construct_db';

my %types = ( row1 => 'VARCHAR(10)', row2 => 'INTEGER', row3 => 'VARCHAR(20)' );

my %columns = ( row1 => '1', row2 => '2', row3 => '3' );

my %column_alias = ( row1 => 'Name', row2 => 'Age', row3 => 'SocialID' );

	my $sqlgen = new SQL::Generator( lang => 'MYSQL', post => ";\n\n", autoprint => 1 ) or print 'not ';

printf "ok %d\n", ++$loaded;

		print $sqlgen->INSERT(

			COLS => [ keys %columns ],

			VALUES => [ values %columns ],

			INTO => $table

			);

		print $sqlgen->INSERT(

			SET => \%columns ,

			INTO => $table

			);

	eval
	{
		1;
	};

	print 'not' if $@;

printf "ok %d\n", ++$loaded;
