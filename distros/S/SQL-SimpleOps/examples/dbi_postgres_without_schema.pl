#!/usr/bin/perl 
#
## CopyRight (C) - Carlos Celso
#
## see: https://metacpan.org/pod/DBD::Pg
#
## /var/lib/pgsql/data/pg_hba.conf
#
	use SQL::SimpleOps;
	use IO::File;

	print "\n## [env] system required environments\n";
	my $err=0;
	foreach my $env(qw(MY_DB MY_USER MY_PASSWORD))
	{
		print "[sysenv] $env is ".($ENV{$env} || "missing, use: 'export $env=' to define the value")."\n";
		$err++ if (!defined($ENV{$env}));
	}
	if ($err)
	{
		print "[sysenv] aborted, required environments is missing\n";
		exit(-1);
	}
	print "[sysenv] successful\n";

	print "\n## [db] calling SQL::SimpleOps\n";

	my $dbh = SQL::SimpleOps->new
	(
		driver => 'pg',
		db => $ENV{MY_DB},
		login => $ENV{MY_USER},
		password => $ENV{MY_PASSWORD},
		server => 'localhost',
	) || die "SQL::SimpleOps errors";

	print "\n## [db] inserting, user1, user2, user3, user4\n";

	$dbh->Insert
	(
		table => 'my_users',
		fields => [ qw(login password uid gid name home shell) ],
		values =>
		[
			[ qw(user1 user1_pw 1 10 user1_inserted user1_home user1_shell) ],
			[ qw(user2 user2_pw 2 20 user2_inserted user2_home user2_shell) ],
			[ qw(user3 user3_pw 3 30 user3_inserted user3_home user3_shell) ],
			[ qw(user4 user4_pw 4 40 user4_inserted user4_home user4_shell) ],
		],
	);
	print "[insert] rc:", $dbh->getRC().", sql: ".$dbh->getLastSQL()."\n";

	print "\n## [db] updating, user1\n";

	$dbh->Update
	(
		table => 'my_users',
		fields =>
		{
			name => 'user1_updated',
		},
		where =>
		[
			login => 'user1',
		],
	);
	print "[update] rc:", $dbh->getRC().", sql: ".$dbh->getLastSQL()."\n";

	print "\n## [db] deleting, user2, user3\n";

	$dbh->Delete
	(
		table => 'my_users',
		where =>
		[
			login => ['user2','user3'],
		],
	);
	print "[insert] rc:", $dbh->getRC().", sql: ".$dbh->getLastSQL()."\n";

	print "\n## [db] selecting\n";

	$dbh->Select
	(
		table => 'my_users',
		buffer => \&callback,
	);
	print "[select] rc:", $dbh->getRC().", sql: ".$dbh->getLastSQL()."\n";
	print "[select] rows:", $dbh->getRows()."\n";

	print "\n## [db] delete all\n";

	$dbh->Delete
	(
		table => 'my_users',
		force => 1,
	);
	print "[delete] rc:", $dbh->getRC().", sql: ".$dbh->getLastSQL()."\n";
	exit;

sub callback()
{
	my $ref = shift;
	my @buf;
	foreach my $id (sort(keys(%{$ref}))) { push(@buf,$id."=".$ref->{$id}); }
	print "[buffer] ".join(", ",@buf)."\n";
	return 0;
}

__END__
