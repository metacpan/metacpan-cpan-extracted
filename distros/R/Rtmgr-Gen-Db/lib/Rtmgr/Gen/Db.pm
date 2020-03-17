package Rtmgr::Gen::Db;

use 5.006;
use strict;
use warnings;
use diagnostics;
use XML::RPC;
use Data::Dump qw(dump);
use DBI;

use Exporter 'import';
our @EXPORT_OK = qw(get_download_list create_db_table get_name get_tracker calc_scene insert_into_database_missing get_difference_between_server_and_database add_remove_extraneous_reccords);
	
=head1 NAME

Rtmgr::Gen::Db - Connect to rTorrent/ruTorrent installation and get a list of torrents, storing them to a database.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

Connects to a rTorrent/ruTorrent installation.

This module connects to an installation of rTorrent/ruTorrent and builds a local SQLite database with the content of the seedbox.

=head1 SUBROUTINES/METHODS

#!/usr/bin/env perl
use Data::Dump qw(dump);

use Rtmgr::Gen qw(get_download_list create_db_table get_name get_tracker calc_scene insert_into_database_missing get_difference_between_server_and_database add_remove_extr$
# Create Database.
my $create_db = create_db_table('database');
print $create_db;

# Populate database with ID's 'HASH' of torrents.
my $dl_list_arr_ref = get_download_list('user','password','host','443','RPC2','database');
insert_into_database_missing($dl_list_arr_ref,'database');

# Remove Extraneous Reccords from Database.
my $dl_list_ext_reccords = get_download_list('user','password','host','443','RPC2','database');
my $diff_list = get_difference_between_server_and_database($dl_list_ext_reccords,'database');
add_remove_extraneous_reccords($diff_list,'database');

# Populate database with Torrent Names.
my $get_name = get_name('user','password','host','443','RPC2','database');
print $get_name;

# Populate database with trackers.
my $get_tracker = get_tracker('user','password','host','443','RPC2','database');
print $get_tracker;

# Check if release is a scene release by checking for entry in srrdb.
my $calc_scene = calc_scene('user','password','database');
print $calc_scene;

=head2 get

=cut
sub create_db_table {
	my ($s_file) = @_;

	# Check to see if file exists or not. If not create it.
	if (-e "$s_file".".db") {
		print "\nDatabase exists.\n";
	} else {
		print "\nCreating Database...\n";
			# Open SQLite database.
			my $driver   = "SQLite"; 
			my $database = "$s_file.db";
			my $dsn = "DBI:$driver:dbname=$database";
			my $userid = ""; # Not implemented no need for database security on local filesystem at this time.
			my $password = ""; # Not implemented.
			my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

				print "Opened database successfully\n";

			# Create the database tables.
				my $stmt = qq(CREATE TABLE SEEDBOX
						(ID TEXT PRIMARY KEY NOT NULL,
						BLANK	TEXT	NOT NULL,
						SCENE	TEXT	NOT NULL,
						TRACKER	TEXT	NOT NULL,
						NAME	TEXT	NOT NULL););
			# Error checking.
				my $rv = $dbh->do($stmt);
				if($rv < 0) {
				   print $DBI::errstr;
				} else {
				   print "Table created successfully\n";
				}
				$dbh->disconnect();	
	}
}

sub get_download_list {
	my ($s_user, $s_pw, $s_url, $s_port, $s_endp, $s_file) = @_;
## Validate input from ARGV
	if (not defined $s_user) { die "USEAGE: Missing server user.\n"; }
	if (not defined $s_pw) { die "USEAGE: Missing server password.\n"; }
	if (not defined $s_url) { die "USEAGE: Missing server url.\n"; }
	if (not defined $s_port) { die "USEAGE: Missing server port.\n"; }
	if (not defined $s_endp) { die "USEAGE: Missing server endpoint.\n"; }
	if (not defined $s_file) { die "USEAGE: Missing server db-filename.\n"; }
	# Run Example: perl gen-db.pl user pass host port endpoint
	my $xmlrpc = XML::RPC->new("https://$s_user\:$s_pw\@$s_url\:$s_port\/$s_endp");

	return $xmlrpc->call( 'download_list' );
}

sub insert_into_database_missing {
	foreach my $i (@{ $_[0] }){
		my $hash_search = _lookup_hash($_[1],$i);
		if ($hash_search == '0') {
			print "HASH: NOT IN DATABSE ... Adding ...\n";
			# Open SQLite database.
			my $driver   = "SQLite";
			my $database = "$_[1].db";
			my $dsn = "DBI:$driver:dbname=$database";
			my $userid = ""; # Not implemented no need for database security on local filesystem at this time.
			my $password = ""; # Not implemented.
			my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
			# Insert the value into the database.
				my $stmt = qq(INSERT INTO SEEDBOX (ID,BLANK,SCENE,TRACKER,NAME)
							VALUES ('$i', '', '', '', ''));
				my $rv = $dbh->do($stmt) or die $DBI::errstr;
			$dbh->disconnect();
			} else {
				print "HASH: $i \n";
		}
	}
}

sub get_difference_between_server_and_database {
	# $_[0]; # Reference to download list hash. Dereference with @{ $_[0] }
	# $_[1]; # Scalar of name of database file.

	# Open SQLite database.
	my $driver   = "SQLite"; 
	my $database = "$_[1].db";
	my $dsn = "DBI:$driver:dbname=$database";
	my $userid = ""; # Not implemented no need for database security on local filesystem at this time.
	my $password = ""; # Not implemented.
	my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

	my $stmt = qq(SELECT ID from SEEDBOX;);
	my $sth = $dbh->prepare( $stmt );
	my $rv = $sth->execute() or die $DBI::errstr;
	
	my @disk_array;
	# Go through every item in database in while loop.
	while(my @row = $sth->fetchrow_array()){
		push(@disk_array, $row[0])
	}
	if( $rv < 0 ) {
		print $DBI::errstr;
	}
		# Check if there is a difference between the two arrays.
		my %diff1;
		my %diff2;

		@diff1{ @disk_array } = @disk_array;
		delete @diff1{ @{ $_[0] } };
		# %diff1 contains elements from '@disk_array' that are not in '@{ $_[0] }'

		@diff2{ @{ $_[0] } } = @{ $_[0] };
		delete @diff2{ @disk_array };
		# %diff2 contains elements from '@{ $_[0] }' that are not in '@disk_array'

		my @k = (keys %diff1, keys %diff2);

		return(\@k);

$dbh->disconnect();
}

sub add_remove_extraneous_reccords{
	# Open SQLite database.
	my $driver   = "SQLite"; 
	my $database = "$_[1].db";
	my $dsn = "DBI:$driver:dbname=$database";
	my $userid = ""; # Not implemented no need for database security on local filesystem at this time.
	my $password = ""; # Not implemented.
	my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;


	print "\nExtraneous Database Reccords: \n";
		# $_[0] is an array reference to either add or delete from database.
		foreach my $i (@{ $_[0] }){
			print "Key: $i\n";

				my $hash_search = _lookup_hash($_[1],$i);
					if ($hash_search == '0') {
							print "HASH: $i \n\t NOT IN DATABSE ... Adding ...\n";
							my $stmt = qq(INSERT INTO SEEDBOX (ID,BLANK,SCENE,TRACKER,NAME)
										VALUES ('$i', '', '', '', ''));
							my $rv = $dbh->do($stmt) or die $DBI::errstr;
						} else {
							print "Key: $i | Does not belong in database.\n";
							# Delete Operation.
							my $stmt = qq(DELETE from SEEDBOX where ID = $i;);
							my $rv = $dbh->do($stmt) or die $DBI::errstr;							
						}
		}
	$dbh->disconnect();	
}

sub _lookup_hash {
	# This sub is passed the filename of a database, and a hash.
	# If the hash exists in the database it returns the hash.
	# If the hash does not exist in the database returns a 0.
	my ($s_file, $hash) = @_;

	# Open SQLite database.
	my $driver   = "SQLite"; 
	my $database = "$s_file.db";
	my $dsn = "DBI:$driver:dbname=$database";
	my $userid = ""; # Not implemented no need for database security on local filesystem at this time.
	my $password = ""; # Not implemented.
	my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

		# Run a check to see if the hash already exists in database.
		my $stmt = qq(SELECT ID FROM SEEDBOX WHERE ID = "$hash";);
		my $sth = $dbh->prepare( $stmt );
		my $rv = $sth->execute() or die $DBI::errstr;

		my @row = $sth->fetchrow_array();

		if( $rv < 0 ) {
			print $DBI::errstr;
		} else {
			# Check if the $row[0] returned from the database query has a value or not. 
			if(exists($row[0])){
			} else {
				return('0');
			}
		}
	# Disconnect from database.
	$sth->finish();
	$dbh->disconnect();	
}

sub get_name {
	my ($s_user, $s_pw, $s_url, $s_port, $s_endp, $s_file) = @_;

	## Validate input from ARGV
	if (not defined $s_user) { die "USEAGE: Missing server user.\n"; }
	if (not defined $s_pw) { die "USEAGE: Missing server password.\n"; }
	if (not defined $s_url) { die "USEAGE: Missing server url.\n"; }
	if (not defined $s_port) { die "USEAGE: Missing server port.\n"; }
	if (not defined $s_endp) { die "USEAGE: Missing server endpoint.\n"; }
	if (not defined $s_file) { die "USEAGE: Missing server db-filename.\n"; }
	# Run Example: perl gen-db.pl user pass host port endpoint
	my $xmlrpc = XML::RPC->new("https://$s_user\:$s_pw\@$s_url\:$s_port\/$s_endp");

	# Open SQLite database.
	my $driver   = "SQLite"; 
	my $database = "$s_file.db";
	my $dsn = "DBI:$driver:dbname=$database";
	my $userid = ""; # Not implemented no need for database security on local filesystem at this time.
	my $password = ""; # Not implemented.
	my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

	print "Opened database successfully\n";

	# Open database and itterate through it.
	my $stmt = qq(SELECT ID, BLANK, SCENE, TRACKER, NAME from SEEDBOX;);
	my $sth = $dbh->prepare( $stmt );
	my $rv = $sth->execute() or die $DBI::errstr;

	if($rv < 0) {
	   print $DBI::errstr;
	}

	while(my @row = $sth->fetchrow_array()) {
			# Look in $row[4] for a value. if it is empty fetch a name for the hash in $row[0].
			if($row[4]) {
				print "NAME: $row[4]\n";
				} else {
					# Send a call to rtorrent and get the name of the corrisponding hash.
					my $name = $xmlrpc->call( 'd.get_name',"$row[0]" );
					# Update the corrisponding reccord in the database.
					my $stmt = qq(UPDATE SEEDBOX set NAME = "$name" where ID='$row[0]';);
					my $rv = $dbh->do($stmt) or die $DBI::errstr;

					if( $rv < 0 ) { 
						print $DBI::errstr;
					} else {
						print "ADDED: $name\n";
					}
			}
	}
		print "Operation done successfully\n";
	# Disconnect from database.
	$dbh->disconnect();	
}

sub get_tracker {
	my ($s_user, $s_pw, $s_url, $s_port, $s_endp, $s_file) = @_;

	## Validate input from ARGV
	if (not defined $s_user) { die "USEAGE: Missing server user.\n"; }
	if (not defined $s_pw) { die "USEAGE: Missing server password.\n"; }
	if (not defined $s_url) { die "USEAGE: Missing server url.\n"; }
	if (not defined $s_port) { die "USEAGE: Missing server port.\n"; }
	if (not defined $s_endp) { die "USEAGE: Missing server endpoint.\n"; }
	if (not defined $s_file) { die "USEAGE: Missing server db-filename.\n"; }
	# Run Example: perl gen-db.pl user pass host port endpoint
	my $xmlrpc = XML::RPC->new("https://$s_user\:$s_pw\@$s_url\:$s_port\/$s_endp");
#	my $dl_list = $xmlrpc->call( 'download_list' );

# Open SQLite database.
	my $driver   = "SQLite"; 
	my $database = "$s_file.db";
	my $dsn = "DBI:$driver:dbname=$database";
	my $userid = ""; # Not implemented no need for database security on local filesystem at this time.
	my $password = ""; # Not implemented.
	my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

	print "Opened database successfully\n";
	
# Open database and itterate through it.
	my $stmt = qq(SELECT ID, BLANK, SCENE, TRACKER, NAME from SEEDBOX;);
	my $sth = $dbh->prepare( $stmt );
	my $rv = $sth->execute() or die $DBI::errstr;

	if($rv < 0) {
	   print $DBI::errstr;
	}
	while(my @row = $sth->fetchrow_array()) {
			# Check to see if the NAME value is populated.
			if($row[3]) {
				print "HASH: ".$row[0]."\tBLANK: ".$row[1]."\tSCENE: ".$row[2]."\n\tTRACKER: ".$row[3]."\n\tNAME: ".$row[4]."\n";
			} else {
		      	# Get name for specific reccord in the loop.
		      	my $url = $xmlrpc->call( 't.url',"$row[0]:t0" );
		      	#dump($url); # Dump the call for testing purposes.
		      	# Update reccords.
				my $stmt = qq(UPDATE SEEDBOX set TRACKER = "$url" where ID='$row[0]';);
				my $rv = $dbh->do($stmt) or die $DBI::errstr;

				if( $rv < 0 ) {
				   print $DBI::errstr;
				} else {
				print "HASH: ".$row[0]."\tBLANK: ".$row[1]."\tSCENE: ".$row[2]."\n\tTRACKER: ".$url."\n\tNAME: ".$row[4]."\n";
				}	
			}
	}
	print "Operation done successfully\n";
	# Disconnect from database.
	$dbh->disconnect();	
}

sub calc_scene {
	my ($s_usr, $s_pw, $s_file) = @_;

	print "Active Database: $s_file\n";

	# Open SQLite database.
	my $driver   = "SQLite"; 
	my $database = "$s_file.db";
	my $dsn = "DBI:$driver:dbname=$database";
	my $userid = ""; # Not implemented no need for database security on local filesystem at this time.
	my $password = ""; # Not implemented.
	my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

	print "Opened database successfully\n";
	
# Open database and itterate through it.
	my $stmt = qq(SELECT ID, BLANK, SCENE, TRACKER, NAME from SEEDBOX;);
	my $sth = $dbh->prepare( $stmt );
	my $rv = $sth->execute() or die $DBI::errstr;

	if($rv < 0) {
	   print $DBI::errstr;
	}

	while(my @row = $sth->fetchrow_array()) {
			# Check to see if the NAME value is populated.
			print "\nID: $row[0]\t";

			if($row[2]) {
				print "\tsrrDB:  $row[2]\n";
				print "\tTRACKER: $row[3]\n";
				print "\tNAME: $row[4]\n";
			} else {
				print "\n\t * * * Searching * * * $row[4]\n";
				my $srrdb_query = qx(srrdb --username=$s_usr --password=$s_pw -s "$row[4]");

				# Create Database Reccord.
				my $stmt = qq(UPDATE SEEDBOX set SCENE = "$srrdb_query" where ID='$row[0]';);
				my $rv = $dbh->do($stmt) or die $DBI::errstr;
				if( $rv < 0 ) { 
					print $DBI::errstr;
				} else {
					print "\tsrrDB: $srrdb_query\n";
					print "\tTRACKER: $row[3]\n";
					print "\tNAME: $row[4].\n";
				}
			}

			print "\t---\n";
	}
	print "\nOperation done successfully\n";

	# Disconnect from database.
	$dbh->disconnect();	
}

=head1 AUTHOR

Clem Morton, C<< <clem at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rtmgr-gen-db at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rtmgr-Gen-Db>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rtmgr::Gen::Db

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Rtmgr-Gen-Db>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rtmgr-Gen-Db>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Rtmgr-Gen-Db>

=item * Search CPAN

L<https://metacpan.org/release/Rtmgr-Gen-Db>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Clem Morton.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Rtmgr::Gen::Db
