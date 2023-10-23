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

	my @mysql_commands;
	my $mysql_module;
	my %mysql_contents;

	1;

################################################################################

sub MySQL_envfail()
{
	diag("MySQL/MariaDB tests IGNORED");
	diag("");
	if (@_) { diag(@_); diag(""); }
	diag("See text README how to configure the MySQL/MariaDB tests");
	diag("");
}

################################################################################

sub MySQL_do()
{
	my $dir = shift;
	if (!defined($ENV{SQL_SIMPLE_MYSQL}) || $ENV{SQL_SIMPLE_MYSQL} eq "")
	{
		&MySQL_envfail();
		return 0;
	}
	if (!defined($ENV{SQL_SIMPLE_MYSQL_DB}) || $ENV{SQL_SIMPLE_MYSQL_DB} eq "")
	{
		&MySQL_envfail("SQL_SIMPLE_MYSQL_DB is missing");
		return 0;
	}

	note("MySQL/MariaDB tests");
	note("");

	$ENV{SQL_SIMPLE_MYSQL_SERVER} = "localhost" if (!defined($ENV{SQL_SIMPLE_MYSQL_SERVER}) || $ENV{SQL_SIMPLE_MYSQL_SERVER} eq "");

	if (&MySQL_Load($dir))
	{
		if ($ENV{SQL_SIMPLE_DB_TEST_SKIP_CREATE} eq "1" || &MySQL_Call("Creating database, tables and rules",\@mysql_commands))
		{
			&MySQL_Test($dir);
			&MySQL_Drop($dir);
		}
	}
	note("MySQL/MariaDB done");
	note("");
	return 1;
}

################################################################################

sub MySQL_Load()
{
	my $dir = shift;
	my $fh = new IO::File("$dir/testDB_mysql.sql");
	if (!defined($fh))
	{
		fail("No SQL commands");
		return 0;
	}
	my $ix;
	my @cmds;
	my $hostname = (defined($ENV{SQL_SIMPLE_MYSQL_SERVER}) && $ENV{SQL_SIMPLE_MYSQL_SERVER} ne "") ? $ENV{SQL_SIMPLE_MYSQL_SERVER} : "localhost";
	foreach my $line(<$fh>)
	{
		$line =~ s/[\n\r]//g;
		$line =~ tr/\t]/ /;

		next if ($line =~ /^-/);	# ignore comments
		next if ($line =~ /^$/);	# ignore blank lines

		$ix = @mysql_commands if ($line =~ /^\w/);


		# chave envs
		$line =~ s/%DSNAME%/$ENV{SQL_SIMPLE_MYSQL_DB}/g;
		$line =~ s/%HOSTNAME%/$hostname/g;
		push(@cmds,$line);

		# remove spaces
		$line =~ s/^\s+|\s+$//g;

		# merge line
		$mysql_commands[$ix] .= $line." ";
	}
	undef($fh);

	if (defined($ENV{SQL_SIMPLE_DB_SHOW_CREATE}) && $ENV{SQL_SIMPLE_DB_SHOW_CREATE} ne "")
	{
		print join("\n",@cmds),"\n";
		return 0;
	}

	pass((@mysql_commands+0)." Commands loaded");

	if	(defined($ENV{SQL_SIMPLE_MYSQL_CLI}) && stat($ENV{SQL_SIMPLE_MYSQL_CLI})) { $mysql_module = $ENV{SQL_SIMPLE_MYSQL_CLI}; }
	if	(stat("/usr/bin/mysql")) { $mysql_module = "/usr/bin/mysql"; }
	elsif	(stat("/usr/bin/mariadb")) { $mysql_module = "/usr/bin/mariadb"; }
	elsif	(stat("/usr/local/bin/mysql")) { $mysql_module = "/usr/local/bin/mysql"; }
	elsif	(stat("/usr/local/bin/mariadb")) { $mysql_module = "/usr/local/bin/mariadb"; }
	else
	{
		fail('No module');
		return 0;
	}
	pass("Module is ".$mysql_module);
	return 1;
}

################################################################################

sub MySQL_Test()
{
	 note("DBD000 Database get contents");

	 my $dbh = &testOPEN
	 (
		interface => "dbi",
		driver => "mysql",
		db => $ENV{SQL_SIMPLE_MYSQL_DB},
		server => $ENV{SQL_SIMPLE_MYSQL_SERVER},
		port => $ENV{SQL_SIMPLE_MYSQL_PORT},
		login => $ENV{SQL_SIMPLE_MYSQL_USER},
		password => $ENV{SQL_SIMPLE_MYSQL_PASSWORD},
		log_message => 0,
	 );
	 return 0 if (!$dbh);

	 my @buffer;
	 $dbh->Call
	 (
		 command => "show tables",
		 buffer => \@buffer
	 );
	 if ($dbh->getRC())
	 {
		  fail("Get tables error, ".$dbh->getMessage());
		  return 0;
	 }

	 foreach my $ref(@buffer)
	 {
		foreach my $key(%{$ref})
		{
			my $table_name = 'my_'.$ref->{$key};
			my @fields;
			$dbh->Call
			(
				command => "desc ".$ref->{$key},
				buffer => \@fields
			);
			$mysql_contents{$table_name}{name} = $ref->{$key};
			foreach my $ref(@fields)
			{
				$mysql_contents{$table_name}{cols}{'my_'.$ref->{Field}} = $ref->{Field};
				$mysql_contents{$table_name}{refs}{'my_'.$ref->{Field}} = $ref;
				$mysql_contents{$table_name}{info}{'my_'.$ref->{Field}}{I} = $ref->{auto_increment};
				$mysql_contents{$table_name}{info}{'my_'.$ref->{Field}}{T} = $ref->{Type};
			}
			last;
		}
	 }
	 $dbh->Close();

	 note("DBD010 Database open contents");

	 $dbh = &testOPEN
	 (
		interface => "dbi",
		driver => "mysql",
		db => $ENV{SQL_SIMPLE_MYSQL_DB},
		server => $ENV{SQL_SIMPLE_MYSQL_SERVER},
		port => $ENV{SQL_SIMPLE_MYSQL_PORT},
		login => $ENV{SQL_SIMPLE_MYSQL_USER},
		password => $ENV{SQL_SIMPLE_MYSQL_PASSWORD},
		log_message => 0,
		tables => \%mysql_contents,
	 );
	 if ($dbh->getRC())
	 {
		  fail("Get tables error, ".$dbh->getMessage());
		  return 0;
	 }

	 &testGeneric($dbh,\%mysql_contents) if ($dbh);
}

################################################################################

sub MySQL_Drop()
{
	return 1 if ($ENV{SQL_SIMPLE_DB_TEST_SKIP_CREATE} eq "1");
	my @drop;
	diag("cleanup");
	foreach my $cmd(@mysql_commands)
	{
		push(@drop,$cmd) if ($cmd =~ /^DROP/);
	}
	&MySQL_Call("Cleanup database, tables and rules",\@drop) if (@drop);
	return 1;
}

################################################################################

sub MySQL_Call()
{
	my $oper = shift;
	my $array = shift;

	diag($oper);

	my @options;
	push(@options,"-v") if (defined($ENV{SQL_SIMPLE_MYSQL_DEBUG}) && $ENV{SQL_SIMPLE_MYSQL_DEBUG} ne "");
	push(@options,"-u",$ENV{SQL_SIMPLE_MYSQL_USER}) if (defined($ENV{SQL_SIMPLE_MYSQL_USER}) && $ENV{SQL_SIMPLE_MYSQL_USER} ne "");
	$ENV{MYSQL_PWD} = $ENV{SQL_SIMPLE_MYSQL_PASSWORD} if (defined($ENV{SQL_SIMPLE_MYSQL_PASSWORD}) && $ENV{SQL_SIMPLE_MYSQL_PASSWORD} ne "");

	my $fh = new IO::File("|".$mysql_module." ".join(" ",@options));
	if (!defined($fh))
	{
		fail("error, ".$!);
		return 0;
	}
	print $fh join("\n",@{$array})."\n";
	close($fh);
	undef($fh);
	pass("done");
	return 1;
}

__END__
