#!/usr/bin/perl
#
## CopyRight (C) - Carlos Celso
#
## see: https://metacpan.org/pod/DBD::CSV
#
	use SQL::SimpleOps;
	use IO::File;

	my $users = "/tmp/users.csv";

	print "\n## [db] calling SQL::SimpleOps\n";

	my $dbh = SQL::SimpleOps->new
	(
		driver => 'CSV',
		dsname => '',
		interface_options =>
		{
			f_schema         => undef,
			f_dir            => "/tmp",
			f_dir_search     => [],
			f_ext            => ".csv",
			f_lock           => 2,
			f_encoding       => "utf8",
			csv_eol          => "\r\n",
			csv_sep_char     => ":",
			csv_quote_char   => '"',
			csv_escape_char  => '"',
			csv_class        => "Text::CSV_XS",
			csv_null         => 1,
			csv_bom          => 0,
			RaiseError       => 1,
			PrintError       => 1,
			FetchHashKeyName => "NAME_lc",
		},
		message_warning_off => 1,
	) || die "SQL::SimpleOps errors";

	print "\n## [file] creating $users, user0, user1, user2\n";

	my $fh = IO::File->new(">".$users) || die "open $users error";
	print $fh join(":",qw(login password uid gid name home shell)),"\n";
	print $fh join(":",qw(user0 user0_pw user0_uid user0_gid user0_embeded user0_home user0_shell)),"\n";
	print $fh join(":",qw(user1 user1_pw user1_uid user1_gid user1_embeded user1_home user1_shell)),"\n";
	print $fh join(":",qw(user2 user2_pw user2_uid user2_gid user2_embeded user2_home user2_shell)),"\n";
	undef($fh);

	print "\n## [db] inserting $users, user3, user4\n";

	$dbh->Insert
	(
		table => 'users',
		fields => [ qw(login password uid gid name home shell) ],
		values =>
		[
			[ qw(user3 user3_pw user3_uid user3_gid user3_inserted user3_home user3_shell) ],
			[ qw(user4 user4_pw user4_uid user4_gid user4_inserted user4_home user4_shell) ],
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
	print "[select] rc:", $dbh->getRC()."\n";
	print "[select] rows:", $dbh->getRows()."\n";

	print "\n## [file] show $users\n";

	my $fh = IO::File->new($users) || die "open $users error";
	while (!$fh->eof) { print <$fh>; }
	undef($fh);

	print "\n## [file] removing $users, use: 'export NO_REMOVE=1' to keep the file\n";

	if ($ENV{NO_REMOVE})
	{
	       	print ".. remove skipped\n";
       	}
       	else
       	{
	       	print ".. removed, rc=".unlink($users),"\n";
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
