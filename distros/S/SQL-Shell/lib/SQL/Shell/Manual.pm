package SQL::Shell::Manual;

use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;

1;

=head1 NAME

SQL::Shell::Manual - user guide for sql shell

=head1 SYNOPSIS

sqlsh -d DBI:Oracle:IFLDEV -u scott -p tiger

=head1 DESCRIPTION

This is a guide to using sqlsh.  sqlsh is an interactive shell run from the command-line for workling with databases.
It can also be run in "batch mode" taking a list of commands from stdin (using the -i switch) or you can pass a single command to it on the command-line.

=head2 Connecting

Either set a DSN in the environment as DBI_DSN, supply with the -d option or use the connect command:

	unixbox% sqlsh
	unixbox% sqlsh -d DBI:Oracle:IFLDEV -u scott -p tiger

You can also connect from inside sqlsh:

	unixbox% sqlsh
	> connect DBI:Oracle:IFLDEV scott tiger
	DBI:Oracle:IFLDEV> show $dbh Name
	+--------+
	| Name   |
	+--------+
	| IFLDEV |
	+--------+

and disconnect:

	DBI:Oracle:IFLDEV> disconnect                                 
	> show $dbh Name
	Not connected to database.

If you don't supply a password, sqlsh will prompt you:

	unixbox% sqlsh -d DBI:Oracle:IFLDEV -u scott
	Enter password for scott: 

You can specify a blank password by passing -p:

	unixbox% sqlsh -d DBI:Oracle:IFLDEV -u guest -p

From within sqlsh you can get a list of DBI drivers:

	unixbox% sqlsh
	> show drivers
	
	  CSV
	  DBM
	  ExampleP
	  Excel
	  File
	  Multiplex
	  Oracle
	  Proxy
	  SQLite
	  Sponge
	  mysql
	
and a list of possible data sources for a driver:

	unixbox% sqlsh
	> show datasources Oracle
	
	  dbi:Oracle:GISCPS
	  dbi:Oracle:IFL1
	  dbi:Oracle:IFLDEV
	  dbi:Oracle:IFLTEST

Common DBI DSNs include:

	DBI:Oracle:<SID>
	DBI:mysql:<DB>
	DBI:ADO:<DSN>
	DBI:Excel:file=<xls>
	DBI:CSV:f_dir=<dir>
	DBI:SQLite:dbname=<filename>

=head2 Exploring the schema

=head3 show tables

This lists the tables with a rowcount for each:

	DBI:SQLite:dbname=test.db> show tables                    
	+----------------------+------+
	| table                | rows |
	+----------------------+------+
	| "sqlite_master"      | 1    |
	| "sqlite_temp_master" | 0    |
	| "commands"           | 11   |
	+----------------------+------+

For some database drivers this may include some system tables.
	
=head3 desc

Lists the columns in a table:
	
	DBI:Oracle:IFLDEV> desc commands
	+-------------+----------------+------+
	| Field       | Type           | Null |
	+-------------+----------------+------+
	| COMMAND     | VARCHAR2(200)  | YES  |
	| DESCRIPTION | VARCHAR2(1020) | YES  |
	+-------------+----------------+------+
	
=head3 show schema

Lists the columns in a table, for each table in the schema:

	DBI:Oracle:IFLDEV> show schema
	
	schema dump
	COMMANDS:
	+-------------+----------------+------+
	| Field       | Type           | Null |
	+-------------+----------------+------+
	| COMMAND     | VARCHAR2(200)  | YES  |
	| DESCRIPTION | VARCHAR2(1020) | YES  |
	+-------------+----------------+------+

=head2 Querying the database

	DBI:SQLite:dbname=test.db> select * from commands
	+------------------+--------------------------------------------------------------+
	| command          | desc                                                         |
	+------------------+--------------------------------------------------------------+
	| show drivers     | Displays a list of DBI drivers                               |
	| show datasources | Displays a list of available data sources for a driver       |
	| connect          | Connects to a data source                                    |
	| disconnect       | Disconnects from a data source                               |
	| show tables      | List the tables in the schema with a rowcount for each table |
	| show schema      | Lists the columns in each table in the schema                |
	| desc             | List the columns in a table                                  |
	| set              | Set a parameter                                              |
	| help             | Displays sqlsh help in your $PAGER                           |
	| reload           | Reloads sqlsh                                                |
	| exit             | Quits sqlsh                                                  |
	+------------------+--------------------------------------------------------------+

=head3 BLOB values

You can control the amount of BLOB data fetched by setting the C<longreadlen> parameter.

	
	DBI:Oracle:IFLDEV> set longreadlen 4096
	LongReadLen set to '4096'
	
	DBI:Oracle:IFLDEV> show $dbh LongReadLen
	+-------------+
	| LongReadLen |
	+-------------+
	| 4096        |
	+-------------+

 Note that the C<longtruncok> parameter should also be set (it is by default):
 
	DBI:Oracle:IFLDEV> show $dbh LongTruncOk
	+-------------+
	| LongTruncOk |
	+-------------+
	| 1           |
	+-------------+


=head3 Values containing non-word characters

Suppose we have values in our database which contain whitespace characters (e.g. tabs):

	DBI:Oracle:IFLDEV> set enter-whitespace on
	Whitespace may be entered as \n, \r and \t

	DBI:Oracle:IFLDEV> insert into commands(command,description) values('test', 'one\ttwo')
	INSERT commands: 1 rows affected

When we query the table we see these as literal values:

	DBI:Oracle:IFLDEV> select * from commands
	+---------+-------------+
	| COMMAND | DESCRIPTION |
	+---------+-------------+
	| test    | one two     |
	+---------+-------------+

We can instead chose to display them escaped:

	DBI:Oracle:IFLDEV> set escape show-whitespace
	DBI:Oracle:IFLDEV> select * from commands
	+---------+-------------+
	| COMMAND | DESCRIPTION |
	+---------+-------------+
	| test    | one\ttwo    |
	+---------+-------------+

Alternatively we can use uri-escaping:

	DBI:Oracle:IFLDEV> set escape uri-escape on
	DBI:Oracle:IFLDEV> select * from commands
	+---------+-------------+
	| COMMAND | DESCRIPTION |
	+---------+-------------+
	| test    | one%09two   |
	+---------+-------------+

=head3 Entering multi-line statements

To enable multiline mode:

	DBI:Oracle:IFLDEV> set multiline on 

You can then build up statements over multiple lines, ending with a semicolon, e.g.:

	DBI:Oracle:IFLDEV> select 
	DBI:Oracle:IFLDEV> count(*) 
	DBI:Oracle:IFLDEV> from 
	DBI:Oracle:IFLDEV> commands
	DBI:Oracle:IFLDEV> ;
	+----------+
	| COUNT(*) |
	+----------+
	| 11       |
	+----------+

To disable multiline mode, remember you need to end the statement in a semicolon:

	DBI:Oracle:IFLDEV> set multiline off;

=head3 Altering the display mode

The default (C<box>) display mode is similar to that used by the mysql client - it works well for tables of fairly short values. 
The C<record> display mode is good for viewing single records:

	DBI:SQLite:dbname=test.db> set display-mode record
	DBI:SQLite:dbname=test.db> select * from commands where command='desc'
	--------------------------------------------------------------------------------
	command | desc
	desc    | List the columns in a table
	--------------------------------------------------------------------------------

The C<spaced> display mode (despite sounding like a description of sqlsh's author) provides a minimum clutter view of the data.
The C<tabbed> display mode generally looks horrendous but is useful for a quick cut+paste of delimited values.
The C<sql> display mode generates insert statements using a $table placeholder for where the data is to be inserted.
The C<xml> display mode generates element-only XML which can be parsed into a list of hashes with XML::Simple.

=head2 Altering the database

By default transactions are not automatically committed so you must explicitly commit them:

	DBI:Oracle:IFLDEV> insert into commands(command, description) values ('dump','Writes a table or query results to a delimited file')
	INSERT commands: 1 rows affected
	
	DBI:Oracle:IFLDEV> commit

and you can roll back mistakes:
	
	DBI:Oracle:IFLDEV> delete from commands
	DELETE commands: 11 rows affected
	
	DBI:Oracle:IFLDEV> rollback
	DBI:Oracle:IFLDEV> select count(*) from commands         
	+----------+
	| COUNT(*) |
	+----------+
	| 11       |
	+----------+

If you prefer to live dangerously you can switch autocommit on:
	
	set autocommit on
	insert ...
	update ...

=head3 Clearing the database

The C<wipe tables> command can be used to remove all the data each of the tables in the database:

	DBI:Oracle:IFLDEV> wipe tables       
	Wipe all data from:
	
	  COMMANDS
	
	Are you sure you want to do this? (type 'yes' if you are) yes
	
	Wiped all data in database

It prompts you to confirm before anihilating your database.
			
=head2 Dumping delimited data

C<dump> can either be used to dump an entire table:

	dump mytable into export.txt
	
or the rowset resulting from a query:
	
	dump select type, count(*) from mytable group by type into histogram.txt delimited by :

An example:

	DBI:SQLite:dbname=test.db> dump commands into commands.csv delimited by ,
	Dumping commands into commands.csv
	Dumped 11 rows into commands.csv
	
	DBI:SQLite:dbname=test.db> more commands.csv 
	command,desc
	show drivers,Displays a list of DBI drivers
	show datasources,Displays a list of available data sources for a driver
	connect,Connects to a data source
	disconnect,Disconnects from a data source
	show tables,List the tables in the schema with a rowcount for each table
	show schema,Lists the columns in each table in the schema
	desc,List the columns in a table
	set,Set a parameter
	help,Displays sqlsh help in your $PAGER
	reload,Reloads sqlsh
	exit,Quits sqlsh

You can also dump all the tables in a database into a directory:

	dump all tables into dumpdir/

=head2 Logging

You can chose to log commands:

	log commands logfile.txt

or query results:
	
	log queries dumpfile.txt

or both:

	log all history.log

=head2 Exporting data as XML

	DBI:Oracle:IFLDEV> set log-mode xml 
	
	DBI:Oracle:IFLDEV> log queries export.xml
	Logging queries to export.xml
	
	DBI:Oracle:IFLDEV>> select * from commands where command like 'show%'
	+------------------+--------------------------------------------------------------+
	| COMMAND          | DESCRIPTION                                                  |
	+------------------+--------------------------------------------------------------+
	| show drivers     | Displays a list of DBI drivers                               |
	| show datasources | Displays a list of available data sources for a driver       |
	| show tables      | List the tables in the schema with a rowcount for each table |
	| show schema      | Lists the columns in each table in the schema                |
	+------------------+--------------------------------------------------------------+

	DBI:Oracle:IFLDEV>> more export.xml
	<rowset>
	        <record>
	                <COMMAND>show drivers</COMMAND>
	                <DESCRIPTION>Displays a list of DBI drivers</DESCRIPTION>
	        </record>
	        <record>
	                <COMMAND>show datasources</COMMAND>
	                <DESCRIPTION>Displays a list of available data sources for a driver</DESCRIPTION>
	        </record>
	        <record>
	                <COMMAND>show tables</COMMAND>
	                <DESCRIPTION>List the tables in the schema with a rowcount for each table</DESCRIPTION>
	        </record>
	        <record>
	                <COMMAND>show schema</COMMAND>
	                <DESCRIPTION>Lists the columns in each table in the schema</DESCRIPTION>
	        </record>
	</rowset>
	
	DBI:Oracle:IFLDEV>> no log
	Stopped logging queries

=head2 Exporting data as SQL

	DBI:Oracle:IFLDEV> set log-mode sql

	DBI:Oracle:IFLDEV> log queries export.sql                           
	Logging queries to export.sql

	DBI:Oracle:IFLDEV>> select * from commands where command like 'show%'
	+------------------+--------------------------------------------------------------+
	| COMMAND          | DESCRIPTION                                                  |
	+------------------+--------------------------------------------------------------+
	| show drivers     | Displays a list of DBI drivers                               |
	| show datasources | Displays a list of available data sources for a driver       |
	| show tables      | List the tables in the schema with a rowcount for each table |
	| show schema      | Lists the columns in each table in the schema                |
	+------------------+--------------------------------------------------------------+

	DBI:Oracle:IFLDEV>> more export.sql                                  
	INSERT into $table (COMMAND,DESCRIPTION) VALUES ('show drivers','Displays a list of DBI drivers');
	INSERT into $table (COMMAND,DESCRIPTION) VALUES ('show datasources','Displays a list of available data sources for a driver');
	INSERT into $table (COMMAND,DESCRIPTION) VALUES ('show tables','List the tables in the schema with a rowcount for each table');
	INSERT into $table (COMMAND,DESCRIPTION) VALUES ('show schema','Lists the columns in each table in the schema');
	
	DBI:Oracle:IFLDEV>> no log
	Stopped logging queries

You can then replace $table with the table name you want the INSERT stataments to be issued against:
	
	unixbox% perl -p -i -e 's/\$table/show_commands/' export.sql

=head2 Loading data

Loading a tab-delimited text file is simple:

	load export.txt into mytable

Here's an example:

	DBI:SQLite:dbname=test.db> create table commands(command varchar(50), desc varchar(255))                
	CREATE table commands: 0 rows affected

	DBI:SQLite:dbname=test.db> load commands.tsv into commands
	Loaded 11 rows into commands from commands.tsv

As with C<dump> you can change the delimiter character:

	load export.csv into mytable delimited by ,
	
You can also specify character set translations:	

	load export.txt into mytable from CP1252 to UTF-8

if your database engine cannot do the character set conversions itself.
See L<Locale::Recode> for a list of character set names.

=head2 Manipulating the command history

You can dump out the history to a file:

	save history to history.txt
	
You can also load in a set of commands into the history:
	
	load history from handy_queries.sql

This can be useful in conjunction with C<log commands>.
You can clear the history at any time with:

	clear history

and display it with:
	
	show history
	
=head2 Running batches of commands

You can execute a sequence of sqlsh commands from a file:

	> execute commands.sqlsh

that might have been generated by C<save history> or C<log commands>.
You can also pipe commands into sqlsh on STDIN if you call it with the C<-i> switch:

	unixbox% sqlsh -d DBI:Oracle:IFLDEV -u scott -p tiger -i < commands.sqlsh

=head1 VERSION

$Revision: 1.6 $ on $Date: 2006/08/02 12:01:15 $ by $Author: johna $

=head1 AUTHOR

John Alden

=cut
	