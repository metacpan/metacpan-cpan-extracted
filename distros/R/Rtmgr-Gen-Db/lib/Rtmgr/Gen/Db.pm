package Rtmgr::Gen::Db;

use 5.006;
use strict;
use warnings;
use XML::RPC;
use Data::Dump qw(dump);
use DBI;

use Exporter 'import';
our @EXPORT_OK = qw(get_hash create_db_table get_name get_tracker calc_scene);
	
=head1 NAME

Rtmgr::Gen::Db - Connect to rTorrent/ruTorrent installation and get a list of torrents, storing them to a database.!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Connects to a rTorrent/ruTorrent installation.

This module connects to an installation of rTorrent/ruTorrent and builds a local SQLite database with the content of the seedbox.

=head1 SUBROUTINES/METHODS

use Rtmgr::Gen qw(get_hash create_db_table get_name get_tracker);

my $create_db = create_db_table('database');
print $create_db;

my $get_hash = get_hash('user','password','host','443','RPC2','database');
print $get_hash;

my $get_name = get_name('user','password','host','443','RPC2','database');
print $get_name;

my $get_tracker = get_tracker('user','password','host','443','RPC2','database');
print $get_tracker;

=head2 get

=cut
sub create_db_table {
	my ($s_file) = @_;

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
			(ID INT PRIMARY KEY NOT NULL,
			HASH	TEXT	NOT NULL,
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


sub get_hash {
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
	my $dl_list = $xmlrpc->call( 'download_list' );
# Open SQLite database.
	my $driver   = "SQLite"; 
	my $database = "$s_file.db";
	my $dsn = "DBI:$driver:dbname=$database";
	my $userid = ""; # Not implemented no need for database security on local filesystem at this time.
	my $password = ""; # Not implemented.
	my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

	print "Opened database successfully\n";
# Insert into database each hash returned from $dl_list
	my $n=0;
	foreach my $i (@{ $dl_list}){
		#my $name = $xmlrpc->call( 'd.get_name',$i );
		my $stmt = qq(INSERT INTO SEEDBOX (ID,HASH,SCENE,TRACKER,NAME)
			VALUES ($n, "$i", '', '', ''));
		my $rv = $dbh->do($stmt) or die $DBI::errstr;
		$n ++;
		print "INDEX: $n |HASH:\t$i\n";
	}
	# Disconnect from database.
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
	my $stmt = qq(SELECT ID, HASH, SCENE, TRACKER, NAME from SEEDBOX;);
	my $sth = $dbh->prepare( $stmt );
	my $rv = $sth->execute() or die $DBI::errstr;

	if($rv < 0) {
	   print $DBI::errstr;
	}

	while(my @row = $sth->fetchrow_array()) {
			# Check to see if the NAME value is populated.
			if($row[4]) {
				print "ID: ".$row[0]."\tHASH: ".$row[1]."\tSCENE: ".$row[2]."\tTRACKER: ".$row[3]."\tNAME: ".$row[4]."\n";
			} else {
		      	# Get name for specific reccord in the loop.
		      	my $name = $xmlrpc->call( 'd.get_name',"$row[1]" );
		      	# Update reccords.
				my $stmt = qq(UPDATE SEEDBOX set NAME = "$name" where ID=$row[0];);
				my $rv = $dbh->do($stmt) or die $DBI::errstr;

				if( $rv < 0 ) {
				   print $DBI::errstr;
				} else {
				print "ID: ".$row[0]."\tHASH: ".$row[1]."\tSCENE: ".$row[2]."\tTRACKER: ".$row[3]."\tNAME: ".$name."\n";
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
	my $stmt = qq(SELECT ID, HASH, SCENE, TRACKER, NAME from SEEDBOX;);
	my $sth = $dbh->prepare( $stmt );
	my $rv = $sth->execute() or die $DBI::errstr;

	if($rv < 0) {
	   print $DBI::errstr;
	}

	while(my @row = $sth->fetchrow_array()) {
			# Check to see if the NAME value is populated.
			if($row[3]) {
				print "ID: ".$row[0]."\tHASH: ".$row[1]."\tSCENE: ".$row[2]."\n\tTRACKER: ".$row[3]."\n\tNAME: ".$row[4]."\n";
			} else {
		      	# Get name for specific reccord in the loop.
		      	my $url = $xmlrpc->call( 't.url',"$row[1]:t0" );
		      	#dump($url); # Dump the call for testing purposes.
		      	# Update reccords.
				my $stmt = qq(UPDATE SEEDBOX set TRACKER = "$url" where ID=$row[0];);
				my $rv = $dbh->do($stmt) or die $DBI::errstr;

				if( $rv < 0 ) {
				   print $DBI::errstr;
				} else {
				print "ID: ".$row[0]."\tHASH: ".$row[1]."\tSCENE: ".$row[2]."\n\tTRACKER: ".$url."\n\tNAME: ".$row[4]."\n";
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
	my $stmt = qq(SELECT ID, HASH, SCENE, TRACKER, NAME from SEEDBOX;);
	my $sth = $dbh->prepare( $stmt );
	my $rv = $sth->execute() or die $DBI::errstr;

	if($rv < 0) {
	   print $DBI::errstr;
	}

	while(my @row = $sth->fetchrow_array()) {
			# Check to see if the NAME value is populated.
			print "\nID: $row[0]  :::\n";

			if($row[2]) {
				print "\tHASH: ".$row[1]."\tSCENE: ".$row[2]."\n\tTRACKER: ".$row[3]."\n\tNAME: ".$row[4]."\n";
			} else {
				print "\tDATABSE: Nothing Found! ... Searching the srrdb...\n";
				print "\t * * * SEARCHING * * * : $row[4]";
				my $srrdb_query = qx(srrdb --username=$s_usr --password=$s_pw -s "$row[4]");
				print "\n\tRESULTS: $srrdb_query\n";

				# Create Database Reccord.
				my $stmt = qq(UPDATE SEEDBOX set SCENE = "$srrdb_query" where ID=$row[0];);
				my $rv = $dbh->do($stmt) or die $DBI::errstr;
				if( $rv < 0 ) { 
					print $DBI::errstr;
				} else {
					print "\tHASH: ".$row[1]."\tSCENE: ".$srrdb_query."\n\tTRACKER: ".$row[3]."\n\tNAME: ".$row[4]."\n";
				}
			}

			print "\t---";
	}
	print "Operation done successfully\n";

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
