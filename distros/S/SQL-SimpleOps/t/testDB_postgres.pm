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

	my @pg_commands;
	my $pg_module;
	my %pg_contents;

	1;


################################################################################

sub PG_envfail()
{
	diag("Postgres tests IGNORED");
	diag("");
	if (@_) { diag(@_); diag(""); }
	diag("see: README.txt how to configure the Postgres tests");
	diag("");
}

################################################################################

sub PG_do()
{
	my $dir = shift;
	if (!defined($ENV{SQL_SIMPLE_PG}) || $ENV{SQL_SIMPLE_PG} eq "")
	{
		&PG_envfail();
		return 0;
	}
	if (!defined($ENV{SQL_SIMPLE_PG_DB}) || $ENV{SQL_SIMPLE_PG_DB} eq "")
	{
		&PG_envfail("SQL_SIMPLE_PG_DB is missing");
		return 0;
	}
	if (!defined($ENV{SQL_SIMPLE_PG_SCHEMA}) || $ENV{SQL_SIMPLE_PG_SCHEMA} eq "")
	{
		&PG_envfail("SQL_SIMPLE_PG_SCHEMA is missing");
		return 0;
	}

	note("Postgres tests");
	note("");

	$ENV{SQL_SIMPLE_PG_SERVER} = "localhost" if (!defined($ENV{SQL_SIMPLE_PG_SERVER}) || $ENV{SQL_SIMPLE_PG_SERVER} eq "");

	if (&PG_Load($dir))
	{
		if ($ENV{SQL_SIMPLE_DB_TEST_SKIP_CREATE} eq "1" || &PG_Call("Creating database, schema, tables and rules",\@pg_commands))
		{
			&PG_Test($dir);
			&PG_Drop($dir);
		}
	}
	note("Postgres done");
	note("");
	return 1;
}

################################################################################E
#
sub PG_Load()
{
	my $dir = shift;
	my $fh = new IO::File("$dir/testDB_postgres.sql");
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

		next if ($line =~ /^-/);	# ignore comments
		next if ($line =~ /^$/);	# ignore blank lines

		$ix = @pg_commands if ($line =~ /^\w/);

		# change envs
		$line =~ s/%SCHEMA%/$ENV{SQL_SIMPLE_PG_SCHEMA}/g;
		$line =~ s/%DSNAME%/$ENV{SQL_SIMPLE_PG_DB}/g;
		push(@cmds,$line);

		# remove spaces
		$line =~ s/^\s+|\s+$//g;

		# merge line
		$pg_commands[$ix] .= $line." ";
	}
	undef($fh);

	if (defined($ENV{SQL_SIMPLE_DB_SHOW_CREATE}) && $ENV{SQL_SIMPLE_DB_SHOW_CREATE} ne "")
	{
		print join("\n",@cmds),"\n";
		return 0;
	}

	for ($ix=0; $ix < @pg_commands; )
	{
		if	($pg_commands[$ix] =~ /^(DROP|CREATE)\s+(DATABASE)/i)
		{
			if (!defined($ENV{SQL_SIMPLE_PG_DB}) || $ENV{SQL_SIMPLE_PG_DB} eq "")
			{
				splice(@pg_commands,$ix,1);
				next;
			}
		}
		elsif	($pg_commands[$ix] =~ /^(DROP|CREATE)\s+(SCHEMA)/i)
		{
			if (!defined($ENV{SQL_SIMPLE_PG_SCHEMA}) || $ENV{SQL_SIMPLE_PG_SCHEMA} eq "")
			{
				splice(@pg_commands,$ix,1);
				next;
			}
		}
		$ix++;
	}

	pass((@pg_commands+0)." Commands loaded");

	if	(defined($ENV{SQL_SIMPLE_PG_CLI}) && stat($ENV{SQL_SIMPLE_PG_CLI})) { $pg_module = $ENV{SQL_SIMPLE_PG_CLI}; }
	elsif	(stat("/usr/bin/psql")) { $pg_module = "/usr/bin/psql"; }
	elsif	(stat("/usr/local/bin/psql")) { $pg_module = "/usr/local/bin/psql"; }
	else
	{
		fail('No module');
		return 0;
	}
	pass("Module is ".$pg_module);
	return 1;
}

################################################################################

sub PG_Test()
{
	note("DBD000 Database get contents");

	my $dbh = &testOPEN
	(
		interface => "dbi",
		driver => "pg",
		db => $ENV{SQL_SIMPLE_PG_DB},
		schema => $ENV{SQL_SIMPLE_PG_SCHEMA},
		server => $ENV{SQL_SIMPLE_PG_SERVER},
		port => $ENV{SQL_SIMPLE_PG_PORT},
		login => $ENV{SQL_SIMPLE_PG_USER},
		password => $ENV{SQL_SIMPLE_PG_PASSWORD},
		log_message => 0,
	);
	return 0 if (!$dbh);

	my $schema = $ENV{SQL_SIMPLE_PG_SCHEMA} || "public";
	my @buffer;
	$dbh->Call
	(
		#command => "select tablename as name from pg_tables where schemaname = '$ENV{SQL_SIMPLE_PG_DB}'",
		command => "select table_name as name from information_schema.tables where table_schema = '$schema'",
		buffer => \@buffer,
		order_by => [ "name" ],
	);
	if ($dbh->getRC())
	{
		&fail("Get tables error, ".$dbh->getMessage());
		return 0;
	}
	if (@buffer == 0)
	{
		diag($dbh->getLastSQL());
		fail("Get tables error");
		return 0;
	}
	foreach my $ref(@buffer)
	{
		next if (!defined($ref->{name}));

		my $table_name = 'my_'.$ref->{name};
		my @fields;
		$dbh->Call
		(
			# column_name
			# data_type
			# is_nullable
			# column_default
			# dtd_identifier
			# ordinal_position
			command => "select ".
				join(",","column_name","data_type","is_nullable","column_default","dtd_identifier","ordinal_position")." ".
			       	"from information_schema.columns ".
				"where table_schema = '$schema' and table_name = '$ref->{name}'",
			buffer => \@fields,
		);
		$pg_contents{$table_name}{name} = $ref->{name};
		foreach my $ref(@fields)
		{
			$pg_contents{$table_name}{cols}{'my_'.$ref->{column_name}} = $ref->{column_name};
			$pg_contents{$table_name}{refs}{'my_'.$ref->{column_name}} = $ref;
			$pg_contents{$table_name}{info}{'my_'.$ref->{column_name}}{I} = ($ref->{column_default}) ? 1 : 0;
			$pg_contents{$table_name}{info}{'my_'.$ref->{column_name}}{T} = $ref->{data_type};
		}
	}
	$dbh->Close();

	if (%pg_contents == 0)
	{
		fail("Get containts error");
		return 0;
	}

	note("DBD010 Database open contents");

	$dbh = &testOPEN
	(
		interface => "dbi",
		driver => "pg",
		db => $ENV{SQL_SIMPLE_PG_DB},
		schema => $ENV{SQL_SIMPLE_PG_SCHEMA},
		server => $ENV{SQL_SIMPLE_PG_SERVER},
		port => $ENV{SQL_SIMPLE_PG_PORT},
		login => $ENV{SQL_SIMPLE_PG_USER},
		password => $ENV{SQL_SIMPLE_PG_PASSWORD},
		log_message => 0,
		tables => \%pg_contents,
	);
	if ($dbh->getRC())
	{
		&fail("Get tables error, ".$dbh->getMessage());
		return 0;
	}

	&testGeneric($dbh,\%pg_contents) if ($dbh);
}

################################################################################

sub PG_Drop()
{
	return 1 if ($ENV{SQL_SIMPLE_DB_TEST_SKIP_CREATE} eq "1");
	my @drop;
	foreach my $cmd(@pg_commands)
	{
		push(@drop,$cmd) if ($cmd =~ /^DROP/);
	}
	&PG_Call("Cleanup database, schema, table and rules",\@drop) if (@drop);
	return 1;
}

################################################################################

sub PG_Call()
{
	my $oper = shift;
	my $array = shift;

	diag($oper);

	my @root;
	my @cmds;
	foreach my $line(@{$array})
	{
		(($line =~ /^DROP\s+/) || ($line =~ /^CREATE\s+DATABASE\s+/)) ? push(@root,$line) : push(@cmds,$line);
	}

	$ENV{PGUSER} = $ENV{SQL_SIMPLE_PG_USER} if (defined($ENV{SQL_SIMPLE_PG_USER}) && $ENV{SQL_SIMPLE_PG_USER} ne "");
	$ENV{PGPASSWORD} = $ENV{SQL_SIMPLE_PG_PASSWORD} if (defined($ENV{SQL_SIMPLE_PG_PASSWORD}) && $ENV{SQL_SIMPLE_PG_PASSWORD} ne "");

	&PG_Call_IO(1,"root",\@root);
	&PG_Call_IO(0,"database",\@cmds);
}

sub PG_Call_IO()
{
	my $is_root = shift;
	my $text = shift;
	my $buffer = shift;
	my $option = shift;

	return if (@{$buffer}==0);

	my @options;
	push(@options,"-b",$ENV{SQL_SIMPLE_PG_DB}) if ($is_root==0 && defined($ENV{SQL_SIMPLE_PG_DB}));
	push(@options,"-a") if (defined($ENV{SQL_SIMPLE_PG_DEBUG}) && $ENV{SQL_SIMPLE_PG_DEBUG} ne "");

	my $fh = new IO::File("|".$pg_module." ".join(" ",@options));
	if (!defined($fh))
	{
		fail($text." error, ".$!);
		return 0;
	}
	print $fh join("\n",@{$buffer})."\n";
	close($fh);
	undef($fh);

	pass($text." done");
	return 1;
}

__END__
