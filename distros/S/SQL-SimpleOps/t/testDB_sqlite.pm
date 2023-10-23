#!/usr/bin/perl
#
## LICENSE AND COPYRIGHT
# 
## Copyright (C) Carlos Celso
# 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
# 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
#
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see L<http://www.gnu.org/licenses/>.
#

	use strict;
	use warnings;

	my @sqlite_commands;
	my $sqlite_module;
	my %sqlite_contents;

	1;

################################################################################

sub SQLite_envfail()
{
	diag("SQLite3 tests IGNORED");
	diag("");
	if (@_) { diag(@_); diag(""); }
	diag("See text README how to configure the SQLite3 tests");
	diag("");
}

################################################################################

sub SQLite_do()
{
	my $dir = shift;
	if (!defined($ENV{SQL_SIMPLE_SQLITE}) || $ENV{SQL_SIMPLE_SQLITE} eq "")
	{
		&SQLite_envfail();
		return 0;
	}

	$ENV{SQL_SIMPLE_SQLITE_DB} = "sql_simple_sqlite_".$$;
	$ENV{SQL_SIMPLE_SQLITE_DBFILE} = "/tmp/".$ENV{SQL_SIMPLE_SQLITE_DB}.".db";

	note("SQLite3 tests");
	note("");

	if (&SQLite_Load($dir))
	{
		if (&SQLite_Call("Creating database file and tables",\@sqlite_commands))
		{
			&SQLite_Test($dir);
			&SQLite_Drop($dir);
		}
	}
	note("SQLite3 done");
	note("");
	return 1;
}

################################################################################

sub SQLite_Load()
{
	my $dir = shift;
	my $fh = new IO::File("$dir/testDB_sqlite.sql");
	if (!defined($fh))
	{
		fail("No SQL commands");
		return 0;
	}
	my $ix;
	my @cmds;
	foreach my $line(<$fh>)
	{
		$line =~ s/[\n\r]//g;
		$line =~ tr/\t]/ /;

		next if ($line =~ /^-/);
		next if ($line =~ /^$/);

		$ix = @sqlite_commands if ($line =~ /^\w/);

		push(@cmds,$line);

		# remove spaces
		$line =~ s/^\s+|\s+$//g;

		# merge line
		$sqlite_commands[$ix] .= $line." ";
	}
	undef($fh);

	if (defined($ENV{SQL_SIMPLE_DB_SHOW_CREATE}) && $ENV{SQL_SIMPLE_DB_SHOW_CREATE} ne "")
	{
		print join("\n",@cmds),"\n";
		return 0;
	}

	pass((@sqlite_commands+0)." Commands loaded");

	if	(defined($ENV{SQL_SIMPLE_SQLITE_CLI}) && stat($ENV{SQL_SIMPLE_SQLITE_CLI})) { $sqlite_module = $ENV{SQL_SIMPLE_SQLITE_CLI}; }
	elsif	(stat("/usr/bin/sqlite3")) { $sqlite_module = "/usr/bin/sqlite3"; }
	elsif	(stat("/usr/local/bin/sqlite3")) { $sqlite_module = "/usr/local/bin/sqlite3"; }
	else
	{
		fail('No module');
		return 0;
	}
	pass("Module is ".$sqlite_module);
	return 1;
}

################################################################################

sub SQLite_Test()
{
	 note("DBD000 Database get contents");

	 my $dbh = &testOPEN
	 (
		  interface => "dbi",
		  driver => "sqlite",
		  db => $ENV{SQL_SIMPLE_SQLITE_DB},
		  dbfile => $ENV{SQL_SIMPLE_SQLITE_DBFILE},
		  log_message => 0,
	 );
	 return 0 if (!$dbh);

	 my @buffer;
	 $dbh->Call ( command => "select name from sqlite_schema where type = 'table'", buffer => \@buffer );
	 if ($dbh->getRC())
	 {
		  &fail("Get tables error, ".$dbh->getMessage());
		  return 0;
	 }
	 foreach my $ref(@buffer)
	 {
		  next if (!defined($ref->{name}));
		  my $table_name = 'my_'.$ref->{name};
		  my @fields;
		  $dbh->Call ( command => "pragma table_info('".$ref->{name}."')", buffer => \@fields );

		  $sqlite_contents{$table_name}{name} = $ref->{name};
		  foreach my $ref(@fields)
		  {
			   $sqlite_contents{$table_name}{cols}{'my_'.$ref->{name}} = $ref->{name};
			   $sqlite_contents{$table_name}{refs}{'my_'.$ref->{name}} = $ref;
			   $sqlite_contents{$table_name}{info}{'my_'.$ref->{name}}{I} = $ref->{pk};
		  }
	 }
	 $dbh->Close();

	 note("DBD010 Database open contents");

	 $dbh = &testOPEN
	 (
		  interface => "dbi",
		  driver => "sqlite",
		  db => $ENV{SQL_SIMPLE_SQLITE_DB},
		  dbfile => $ENV{SQL_SIMPLE_SQLITE_DBFILE},
		  log_message => 0,
		  tables => \%sqlite_contents,
	 );
	 if ($dbh->getRC())
	 {
		  &fail("Get tables error, ".$dbh->getMessage());
		  return 0;
	 }

	 &testGeneric($dbh,\%sqlite_contents) if ($dbh);
}

################################################################################

sub SQLite_Drop()
{
	diag("Cleanup database files and tables");
	return unlink($ENV{SQL_SIMPLE_SQLITE_DBFILE}) if (defined($ENV{SQL_SIMPLE_SQLITE_DBFILE}));
}

###############################################################################

sub SQLite_Call()
{
	my $oper = shift;
	my $array = shift;

	diag($oper);

	my $options = "-batch ";
	$options = "-echo" if (defined($ENV{SQL_SIMPLE_SQLITE_DEBUG}) && $ENV{SQL_SIMPLE_SQLITE_DEBUG} ne "");

	my $fh = new IO::File("|".$sqlite_module." ".$options." ".$ENV{SQL_SIMPLE_SQLITE_DBFILE});
	if (!defined($fh))
	{
		fail("error, ".$!);
		return 0;
	}
	print $fh join("\n",@{$array})."\n";
	undef($fh);
	pass("done");
	return 1;
}

__END__
