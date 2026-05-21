#!/usr/bin/perl 
#
## CopyRight (C) - Carlos Celso
#
## see: https://metacpan.org/pod/DBD::SQLite
#
	use SQL::SimpleOps;
	use IO::File;

	my $users = "/tmp/users.sqlite";

	print "\n## [db] calling SQL::SimpleOps\n";

	my $dbh = SQL::SimpleOps->new
	(
		driver => 'sqlite',
		db => 'test_in_file',
		dbfile => $users,
	) || die "SQL::SimpleOps errors";

	print "\n## [db] create table\n";

	$dbh->Call
	(
		command => 'create table users ( login varchar(128), password varchar(256), uid unsigned integer, gid unsigned integer, name varchar(128), home varchar(256), shell varchar(256))',
	);
	print "[call] rc:", $dbh->getRC().", sql: ".$dbh->getLastSQL()."\n";

	print "\n## [db] inserting $users, user1, user2, user3, user4\n";

	$dbh->Insert
	(
		table => 'users',
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

	print "\n## [db] updating $users, user1\n";

	$dbh->Update
	(
		table => 'users',
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

	print "\n## [db] deleting $users, user2, user3\n";

	$dbh->Delete
	(
		table => 'users',
		where =>
		[
			login => ['user2','user3'],
		],
	);
	print "[insert] rc:", $dbh->getRC().", sql: ".$dbh->getLastSQL()."\n";

	print "\n## [db] selecting $users\n";

	$dbh->Select
	(
		table => 'users',
		buffer => \&callback,
	);
	print "[select] rc:", $dbh->getRC().", sql: ".$dbh->getLastSQL()."\n";
	print "[select] rows:", $dbh->getRows()."\n";

	print "\n## [file] removing $users, use: 'export NO_REMOVE=1' to keep the file\n";

	if ($ENV{NO_REMOVE})
       	{
	       	print ".. remove skipped\n";
       	} 
	else
       	{
	       	print ".. removed, rc=".unlink($users)."\n";
       	}
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
