#!/usr/local/bin/perl

#
# Unit test for SQL::Shell
# Define env vars UNIT_TEST_DSN (+ UNIT_TEST_USER & UNIT_TEST_PASS) to enable testing against a database
#
# $Id: SQL-Shell.t,v 1.7 2006/08/04 09:28:30 johna Exp $
#

use strict;

BEGIN {
	use vars qw($tests);
	$tests = 28;
	$tests += 30 if($ENV{UNIT_TEST_DSN});
	$tests++ if $ENV{ORACLE_HOME}; #Test show datasources if Oracle is available
}

use Test::Assertions::TestScript(tests => $tests);
use SQL::Shell;
use IO::CaptureOutput qw(capture);

#Pick up testing DSN from environment
my $dsn  = $ENV{UNIT_TEST_DSN};
my $user = $ENV{UNIT_TEST_USER};
my $pass = $ENV{UNIT_TEST_PASS};

my $sqlsh = new SQL::Shell({Verbose => 1});

#DBI stuff not requiring a connection
my $output = execute($sqlsh, "show drivers");
ASSERT(scalar $output =~ /Sponge/s, "List drivers");

$output = execute($sqlsh, "show settings");
ASSERT(scalar $output =~ /delimiter/s, "List settings");

#TNS magic makes Oracle is a good choice for this test
if ($ENV{ORACLE_HOME}) {
	my $output = execute($sqlsh, "show datasources Oracle");
	ASSERT(scalar $output =~ /DBI:Oracle/is, "List datasources");
}

#History manipulation
my $get_history = $sqlsh->get('GetHistory');
my $set_history = $sqlsh->get('SetHistory');
execute($sqlsh, "clear history");
ASSERT(EQUAL($get_history->(), ["clear history"]), "history clear/accessor");
execute($sqlsh, "show drivers");
execute($sqlsh, "save history to sqlsh-history.txt");
$set_history->([qw(foo bar)]);
execute($sqlsh, "load history from sqlsh-history.txt");
unlink("sqlsh-history.txt");
$output = execute($sqlsh, "show history");
ASSERT(scalar $output =~ /show drivers/s, "load and save history");

#Command registering
my $capture;
$sqlsh->install_cmds({
	qr/^unittest (.*)$/ => sub {my $self = shift; $capture = shift}
});
$output = execute($sqlsh, "unittest testvalue");
ASSERT($capture eq 'testvalue', "install command");

$sqlsh->uninstall_cmds([
	qr/^unittest (.*)$/
]);
my $error;
($output, $error) = execute($sqlsh, "unittest testvalue");
ASSERT(scalar $error =~ /Unrecognised command 'unittest testvalue'/s, "uninstall command");

#Invalid command/param
($output, $error) = execute($sqlsh, "rubbish");
ASSERT(scalar $error =~ /Unrecognised command 'rubbish'/s, "trap invalid command");
$output = execute($sqlsh, "set rubbish on");
ASSERT(scalar $output =~ /Unknown parameter 'rubbish' for set command/s, "trap invalid param");

#Invalid param values
for my $param (qw(tracing display-mode log-mode escape enter-whitespace width longreadlen longtruncok auto-commit multiline)) {
	$output = execute($sqlsh, "set $param rubbish");
	ASSERT(scalar $output =~ /'rubbish' is an invalid value/s, "trap invalid value for $param");
}


#All these tests require a database connection
if($dsn) 
{
	my $dbh = $sqlsh->connect($dsn, $user, $pass);
	ASSERT($sqlsh->is_connected(), "Connected to database");
	ASSERT(lc($sqlsh->dsn()) eq lc($dsn), "DSN");
	
	#Clear the database for the unit test
	drop_all_tables($dbh);
	
	$output = execute($sqlsh, "create table commands(COMMAND varchar(50), DESCRIPTION varchar(255))");
	ASSERT(scalar $output =~ /CREATE table commands/si, "Created table");
			
	$output = execute($sqlsh, "load data/commands.tsv into commands");
	ASSERT(scalar $output =~ m|Loaded 12 rows into commands from data/commands.tsv|s, "Loaded data");
	
	$output = execute($sqlsh, "show tables");
	ASSERT(scalar $output =~ /commands/si, "Show tables");
	
	$output = execute($sqlsh, "show tablecounts");
	ASSERT(scalar $output =~ /commands/si && scalar $output =~ /\b12\b/s, "Show tablecounts");
		
	#Execute script
	$output = execute($sqlsh, "execute data/sqlsh-commands.txt");
	ASSERT(scalar $output =~ /\s*field.*\n\s*COMMAND.*\n\s*DESCRIPTION/si, "Execute script");
		
	#Dump
	$output = execute($sqlsh, "dump select * from commands into sqlsh-dump.tsv");
	ASSERT(FILES_EQUAL("data/sqlsh-expected-dump.tsv", "sqlsh-dump.tsv"), "dump");
	unlink('sqlsh-dump.tsv');

	#Dump tables
	$output = execute($sqlsh, "dump all tables into .");
	ASSERT(FILES_EQUAL("data/sqlsh-expected-dump.tsv", '"main"."commands".dat'), "dump all tables");
	unlink('"main"."commands".dat') if -f '"main"."commands".dat';
	unlink('"main"."sqlite_master".dat') if -f '"main"."sqlite_master".dat';
	unlink('"temp"."sqlite_temp_master".dat') if -f '"temp"."sqlite_temp_master".dat';
		
	#Logging
	execute($sqlsh, "set log-mode sql");
	execute($sqlsh, "log queries sqlsh-log.sql");
	execute($sqlsh, "select * from commands where command='set'");
	my $expected = READ_FILE("data/sqlsh-expected-log.sql");
	execute($sqlsh, "no log");
	ASSERT(FILES_EQUAL("data/sqlsh-expected-log.sql", "sqlsh-log.sql"), "logging");
	unlink('sqlsh-log.sql');
	
	#XML display mode
	execute($sqlsh, "set display-mode xml");
	$output = execute($sqlsh, "select * from commands where command='set'");
	#WRITE_FILE("data/sqlsh-expected.xml", lc($output));
	$expected = READ_FILE("data/sqlsh-expected.xml");
	ASSERT(lc($output) eq $expected, "XML display mode");

	#Show schema
	execute($sqlsh, "set display-mode record");
	$output = execute($sqlsh, "show schema");
	ASSERT(scalar $output =~ /field | command/si && scalar $output =~ /field | description/si, "Show schema");

	#Send commands
	execute($sqlsh, "set display-mode box");
	$output = execute($sqlsh, "send create index idx_commands on commands (command)");
	ASSERT(scalar $output =~ m|CREATE index idx_commands: 1 rows affected|s, "Send command");

	#Recv commands
	$output = execute($sqlsh, "recv pragma main.index_info(idx_commands)");
	ASSERT(scalar $output =~ /command/si, "Recv command");
	execute($sqlsh, "drop index idx_commands");
	
	#Wipe tables
	execute($sqlsh, "set display-mode spaced");
	#execute($sqlsh, "wipe tables");
	execute($sqlsh, "delete from main.commands");
	execute($sqlsh, "commit");
	$output = execute($sqlsh, "show tablecounts");
	ASSERT(scalar $output =~ /commands"?\s+0\b/si, "Wipe tables");

	#Recoding
	$output = execute($sqlsh, "load data/commands2.tsv into commands from UTF-8 to rubbish");
	ASSERT(scalar $output =~ /unrecognised character set 'rubbish'/si, "Check for unrecognised charset");
	$output = execute($sqlsh, "load data/commands2.tsv into commands from UTF-8 to ISO-8859-1");
	$output = execute($sqlsh, "select DESCRIPTION from commands where COMMAND='load data'");
	ASSERT(scalar $output =~ />>\?<</si, "Loaded data with recoding");
	#execute($sqlsh, "wipe tables");
	execute($sqlsh, "delete from main.commands");

	#Escaping
	execute($sqlsh, "set enter-whitespace on");
	execute($sqlsh, "insert into commands(COMMAND, DESCRIPTION) values ('test','one\ntwo three')");
	execute($sqlsh, "set escape escape-whitespace");
	$output = execute($sqlsh, "select * from commands");
	ASSERT(scalar $output =~ /one\\ntwo three/s, "Escape whitespace");
	execute($sqlsh, "set escape show-whitespace");
	$output = execute($sqlsh, "select * from commands");
	ASSERT(scalar $output =~ /one\\ntwo\.three/s, "Show whitespace");
	execute($sqlsh, "set escape uri-escape");
	$output = execute($sqlsh, "select * from commands");
	ASSERT(scalar $output =~ /one%0Atwo%20/s, "URI escape");
	execute($sqlsh, "set escape off");

	#custom renderer
	$sqlsh->install_renderers({'unittest' => \&renderer});
	execute($sqlsh, "set display-mode unittest");
	$output = execute($sqlsh, "select count(*) from commands");
	ASSERT(scalar $output =~ /count\(\*\):1:/s, "Custom renderer");
	$sqlsh->uninstall_renderers(['unittest']);
	$output = execute($sqlsh, "set display-mode unittest");
	ASSERT(scalar $output =~ /'unittest' is an invalid value for display-mode/s, "Uninstall renderer");

	#Record display mode
	$sqlsh->set('Width', 20);
	execute($sqlsh, "set display-mode record");
	$output = execute($sqlsh, "select count(*) from commands");
	ASSERT(scalar $output =~ /--------------------/si, "Width");

	#Roll back transaction
	execute($sqlsh, "rollback");
	$output = execute($sqlsh, "select count(*) from commands");
	ASSERT(scalar $output =~ /count\(\*\) \| 0\b/is, "Rollback");

	#Commit transaction
	execute($sqlsh, "insert into commands(COMMAND, DESCRIPTION) values ('test1','one')");
	execute($sqlsh, "commit");
	execute($sqlsh, "insert into commands(COMMAND, DESCRIPTION) values ('test2','two')");
	execute($sqlsh, "rollback");
	$output = execute($sqlsh, "select count(*) from commands");
	ASSERT(scalar $output =~ /count\(\*\) \| 1\b/is, "Commit");

	#multiline
	execute($sqlsh, "set multiline on");
	$output = execute($sqlsh, "select\ncount(*)\nfrom\ncommands;");
	ASSERT(scalar $output =~ /count\(\*\) \| 1\b/is, "Multiline");	
	execute($sqlsh, "set multiline off;");

	#Database handle manipulations
	execute($sqlsh, "set longreadlen 1000");
	$output = execute($sqlsh, "show \$dbh LongReadLen");
	ASSERT(scalar $output =~ /LongReadLen \| 1000/s, "LongReadLen");
	execute($sqlsh, "set longtruncok on");
	$output = execute($sqlsh, "show \$dbh LongTruncOk");
	ASSERT(scalar $output =~ /LongTruncOk \| 1/s, "LongTruncOk");
	execute($sqlsh, "set auto-commit on");
	$output = execute($sqlsh, "show \$dbh AutoCommit");
	ASSERT(scalar $output =~ /AutoCommit \| 1/s, "AutoCommit");

	#Disconnect
	execute($sqlsh, "disconnect");
	ASSERT(!$sqlsh->is_connected(), "Disconnect");		
	unlink('test.db') if -f 'test.db';
}

#Trap missing database connection
for my $cmd (
	"begin work", 
	"rollback", 
	"commit", 
	"show tables", 
	"show tablecounts", 
	"load data/commands.tsv into commands",
	"execute data/sqlsh-commands.txt",
	"select count(*) from commands",
	"dump commands into sqlsh-dump.tsv",
	"show \$dbh AutoCommit",
) {
	local $^W;
	$output = execute($sqlsh, $cmd);
	my $cmdname = join(" ",(split(/ /, $cmd))[0..1]);
	ASSERT(scalar $output =~ /Not connected to database/s, "$cmdname - check for DB connection");
}

#
# Some helper routines
#

sub execute {
	my ($sqlsh, $cmd) = @_;
	my ($stdout, $stderr);
	capture sub {$sqlsh->execute_cmd($cmd)}, \$stdout, \$stderr;
	TRACE($stdout);
	TRACE($stderr);
	return wantarray? ($stdout, $stderr) : $stdout;
}

sub drop_all_tables {
	my($dbh) = @_;
	TRACE("dropping all tables");
	foreach(SQL::Shell::_list_tables($dbh))
	{
		$dbh->do("drop table $_") unless m/master/i;
	}
}

sub renderer {
	my ($sqlsh, $fh, $headers, $data) = @_;
	my $delim = ",";
	print $fh join($delim, @$headers).":";
	foreach my $row (@$data)
	{	
		print $fh join($delim, @$row).":";
	}				
}
