package Pgreet::DaemonUtils;
#
# File: DaemonUtils.pm
######################################################################
#
#                ** PENGUIN GREETINGS (pgreet) **
#
# A Perl CGI-based web card application for LINUX and probably any
# other UNIX system supporting standard Perl extensions.
#
#   Edouard Lagache, elagache@canebas.org, Copyright (C)  2004-2005
#
# Penguin Greetings (pgreet) consists of a Perl CGI script that
# handles interactions with users wishing to create and/or
# retrieve cards and a system daemon that works behind the scenes
# to store the data and email the cards.
#
# ** This program has been released under GNU GENERAL PUBLIC
# ** LICENSE.  For information, see the COPYING file included
# ** with this code.
#
# For more information and for the latest updates go to the
# Penguin Greetings official web site at:
#
#     http://pgreet.sourceforge.net/
#
# and the SourceForge project page at:
#
#     http://sourceforge.net/projects/pgreet/
#
# ----------
#
#           Perl Module: Pgreet::DaemonUtils
#
# This is the Penguin Greetings (pgreet) module for sharing daemon
# specific routines between the application daemon and command line
# utilities that have similar functionality.
######################################################################
# $Id: DaemonUtils.pm,v 1.15 2005/05/31 16:44:38 elagache Exp $

$VERSION = "1.0.0"; # update after release

# Perl modules.
use DB_File;
# use Data::Dumper; # Needed only for debugging.
use File::Copy;
use File::Spec;
use File::Temp qw(tempdir);

# Simplify output of Data::Dumper
# $Data::Dumper::Terse = 1;

# Perl Pragmas
use strict;

# . . . . . . . . . . Object Methods . . . . . . . . . . . . .

sub new {
#
# Create new object and squirrel away CGI query object
# so that it is available for methods.
#
  my $class = shift;
  my $Pg_config = shift;
  my $Pg_error = shift;

  my $self = {};
  bless $self, $class;

  $self->{'Pg_config'} = $Pg_config;
  $self->{'Pg_error'} = $Pg_error;

  return($self);
}

sub GetDateCode {
#
# function to compute number of days since 1997 as a year code
#
  my ($sec,$min,$hour,$mday,$month,$year,$wday,$yday,$isdst) =
	  localtime(time);

  return((($year - 97) * 365) + $yday);
}

sub backup_db_files {
#
# Convenience method to create backup files of any number
# of subsequent argument filenames to names which are:
# Old_Filename.bak.  Any previous backup filenames are
# deleted.
#
  my $self = shift;
  my @filenames = @_;
  my $Pg_error = $self->{'Pg_error'};

  # Loop through filenames backing up each one.
  foreach my $file (@filenames) {
	unless (copy($file, "$file.bak")) {
	  $Pg_error->report('warn',
						"Unable to make backup copy of file: $file"
					   );
	}
  }
} # End backup_db_files

sub copy_db_files {
#
# Convenience method to copy database files from one
# directory to another takes source and destination
# paths as separate arguments.
#
  my $self = shift;
  my $src_path = shift;
  my $dst_path = shift;
  my @filenames = @_;
  my $Pg_error = $self->{'Pg_error'};

  # Loop through filenames copying from source to destination directory.
  foreach my $file (@filenames) {
	my $src_file = join('/', $src_path, $file);
	my $dst_file = join('/', $dst_path, $file);
	unless (copy($src_file, $dst_file)) {
	  Pg_error->report('warn',
					   "Unable to copy $src_file to $dst_file"
					  );
	}
  }
} #End copy_db_files

sub copy_db_records {
#
# Method to copy the database records using Berkeley DB from
# an old database to a new database file.  The physically
# reorganizes the database and compacts the resulting file.
#
  my $self = shift;
  my $db_file = shift;
  my $src_path = shift;
  my $dst_path = shift;
  my $Pg_error = $self->{'Pg_error'};
  my (%src_db, %dst_db, $key, $record);
  my $rec_cnt = 0;

  my $src_file = join('/', $src_path, $db_file);
  my $dst_file = join('/', $dst_path, $db_file);

  # Open source database - read only.
  unless (tie(%src_db, 'DB_File', $src_file,
			  O_RDONLY, undef, $DB_HASH
			 )
		 ) {
	$Pg_error->report('error',
					  "Unable to open Berk DB file: $src_file for reading"
					 );
  }

  # Create and tie destination database
  unless ((not -e $dst_file) and
          tie(%dst_db, 'DB_File', $dst_file,
			  O_CREAT|O_RDWR, 0644, $DB_HASH
			 )
		 ) {
	$Pg_error->report('error',
					  "Unable to create Berk DB file: $dst_file"
					 );
  }

  # Now copy each record from old to new database.
  while (($key, $record) = each %src_db) {
	$dst_db{$key} = $record;
	$rec_cnt++;
  }

  # Close source file.
  unless (untie(%src_db)) {
	$Pg_error->report('warn',
					  "Could not close card data file: $src_file"
					 );
  }

  # Close destination file.
  unless (untie(%src_db)) {
	$Pg_error->report('warn',
					  "Could not close card data file: $src_file"
					 );
  }
	
  return($rec_cnt); # Return number of records copied.
} # End sub copy_db_records

sub purge_old_cards {
#
# Method to open up database files and checks if
# any records are older than the number of days allowed.
# any records that are too old are purged from the database.
#
  my $self = shift;
  my $path = shift;
  my $DateLimit = shift;
  my $card_name_file = shift;
  my $name_passwd_file = shift;
  my $card_data_file = shift;
  my $Pg_error = $self->{'Pg_error'};
  my (%login_pass, %card_data);
  my ($login, $data_string, $DateCode, $RecordCnt, $PurgeCnt);
  my $TodayDateCode = GetDateCode();

  # Assemble database filenames.
# my $card_name_db = join('/', $path,$card_name_file);
  my $name_passwd_db = join('/', $path, $name_passwd_file);
  my $card_data_db = join('/', $path, $card_data_file);

  # open card data database
  unless (tie(%card_data, 'DB_File', $card_data_db,
			  			  O_RDWR, 0644, $DB_HASH
			 )
		 ) {
	$Pg_error->report('error',
					  "Could not open card data file: $card_data_db"
					 );
  }

  # Open login-password database.
  unless (tie(%login_pass, 'DB_File', $name_passwd_db,
			  			  O_RDWR, 0644, $DB_HASH
			 )
		 ) {
	$Pg_error->report('error',
					  "Could not open card password file: $name_passwd_db"
					 );
  }

  $RecordCnt = 0;
  $PurgeCnt = 0;
  my @login_keys = keys(%card_data);
  foreach $login (@login_keys) {
	$data_string = $card_data{$login};
	unless ( ($DateCode) = $data_string =~ /datecode=(\d+)/) {
	  $Pg_error->report('error',
						"Cannot locate datecode. ",
						"Corrupted database data string: ",
						$data_string
					   );
	}
	if (($TodayDateCode-$DateCode) > $DateLimit) {
	  delete($card_data{$login});
	  delete($login_pass{$login});
	  $PurgeCnt++;
	}
	$RecordCnt++;
  }

  # close login-password database.
  unless (untie(%login_pass)) {
	$Pg_error->report('warn',
					  "Could not close card password file: $name_passwd_db"
					 );
  }


  # Close card database file.
  unless (untie(%card_data)) {
	$Pg_error->report('warn',
					  "Could not close card data file: $card_data_db"
					 );
  }
  return($RecordCnt, $PurgeCnt);
} # End purge_card_data

sub backup_db_purge_old {
#
# "All-in-one" method for safely purging expired card records
# and backing up database files in one method call.
#
  my $self = shift;
  my $db_path = shift;
  my $DateLimit = shift;
  my $card_name_file = shift;
  my $name_passwd_file = shift;
  my $card_data_file = shift;
  my $Pg_error = $self->{'Pg_error'};
  my $TmpDir;

  # Make a backup of database files first
  $self->backup_db_files(join('/', $db_path, $card_name_file),
						 join('/', $db_path, $name_passwd_file),
						 join('/', $db_path, $card_data_file),
						);

  # Try to create a directory to create test values in.
  unless (($TmpDir = tempdir("PgreetDBpurge-XXXXXX", CLEANUP => 1,
							 TMPDIR => 1))
		  and
		  (-d $TmpDir)
		  ){
	$Pg_error->report('error',
					  "Cannot create tmp directory to purge old db records"
					 );
  }

  # Copy database files to a temporary directory
  $self->copy_db_files($db_path, $TmpDir, $card_name_file,
					   $name_passwd_file, $card_data_file,
					  );

  sleep(1); # Pause to avoid undue load on server from one activity

  # Do purge of data
  my ($RecordCnt, $PurgeCnt) =
	$self->purge_old_cards($TmpDir, $DateLimit, $card_name_file,
						   $name_passwd_file, $card_data_file,
						  );

  sleep(1); # Pause to avoid undue load on server from one activity

  # Copy successfully purged files back to source directory
  $self->copy_db_files($TmpDir, $db_path, $card_name_file,
					   $name_passwd_file, $card_data_file,
					  );

  return($RecordCnt, $PurgeCnt);
}


=head1 NAME

Pgreet::DaemonUtils - Penguin Greetings shared routines related to daemon

=head1 SYNOPSIS

  # Constructor:
  $Pg_daemon = new Pgreet::DaemonUtils($Pg_default_config, $Pg_error);

  # Compute number of days since 1997 to "age" ecards
  $DateCode = $Pg_daemon->GetDateCode();

  # Back up any number of database files
  $Pg_daemon->backup_db_files($db_file-1, $db_file-2, $db_file-3,
                              $db_file-4 ...
                             );

  # Copy any number of database files from one location to another
  $Pg_daemon->copy_db_files($src_path, $dst_path,
                            $db_file-1, $db_file-2, $db_file-3,
                            $db_file-4 ...
                            );

  # Copy the database records (using Berkeley DB) from one path to another
  $Pg_daemon->copy_db_records($db_file, $src_path, $dst_path);


  # Purge database of ecard records older than $DateLimit
  $Pg_daemon->purge_old_cards($path, $DateLimit, $card_name_file,
                              $name_passwd_file, $card_data_file
                              );

  # Backup and purge old records in one step.
  $Pg_daemon->backup_db_purge_old($path, $DateLimit, $card_name_file,
                                  $name_passwd_file, $card_data_file
                                 );

=head1 DESCRIPTION

The module C<Pgreet::DaemonUtils> is the Penguin Greetings module for
any routines that must be shared between the application daemon and
command line utilities.  This avoids unnecessary code duplication.
All of these routines involve database manipulation at this time.

=head1 CONSTRUCTING A DAEMONUTILS OBJECT

The C<Pgreet::DaemonUtils> constructor should be called after a
Penguin Greeting configuration object C<Pgreet::Config> and error
object C<Pgreet::Error> has been made.  Since C<Pgreet::DaemonUtils>
does not use the configuration configuration information for some of
it's routines, It is possible to pass it an C<undef> in a command line
utility that is its "configuration-free" routines.  An example
constructor call is below:

  # Constructor:
  $Pg_daemon = new Pgreet::DaemonUtils($Pg_default_config, $Pg_error);


=head1 DATABASE UTILITY METHODS

The object methods for manipulating Berkeley DB databases and related
activities included in C<Pgreet::DaemonUtils> are described below:

=over

=item GetDateCode()

This is a utility method that computes the number of days since
January 1, 1997 to provide some metric for determining how long an
ecard has been in the ecard database.  The C<DateCode> is included in
the information when a card is created.  So subtracting the cards
DateCode from today's DateCode provides the number of days the card
has been in the database.  This method is a simple function and
returns the DateCode.  A simple call is below:

  # Compute number of days since 1997 to "age" ecards
  $DateCode = $Pg_daemon->GetDateCode();

=item backup_db_files()

This method is a convenient tool to create copies of any number of
files with the additional extension C<.bak>.  It is used to create
backup files of the database files before manipulating them.  It takes
any number of file arguments as seen in the sample call below:

  # Back up any number of database files
  $Pg_daemon->backup_db_files($db_file-1, $db_file-2, $db_file-3,
                              $db_file-4 ...
                             );

=item copy_db_files()

This method copies files from one location path to another.  It
requires the source path and destination path as the first two
arguments and then any number of filenames as the remaining arguments.
A sample call is below:

  # Copy any number of database files from one location to another
  $Pg_daemon->copy_db_files($src_path, $dst_path,
                            $db_file-1, $db_file-2, $db_file-3,
                            $db_file-4 ...
                            );

=item copy_db_records()

This method uses the internal Berkeley DB routines (rather than
File::Copy) to copy the database records of a Berkeley DB file from
one path to a new file at another path.  This process compacts the
database in the copy file.  It takes a single Berkeley DB file as its
first argument and then needs the source and destination path as
arguments 2 and 3.  A sample call is below:

  # Copy the database records (using Berkeley DB) from one path to another
  $Pg_daemon->copy_db_records($db_file, $src_path, $dst_path);

=item purge_old_cards()

This method is specific to the task of removing old ecards who have
been in the database for longer than the adminstrator would like.  It
requires 5 arguments: the path to the database files, the datelimit
(in days) that a card should be kept in the database, and the three
database files: $card_name_file, $name_passwd_file, and
$card_data_file.  This method uses the Berkeley DB routines to remove
old records "in place," without making a copy of the database file.
Since over time an ecards site should reach some "equilibrium" with
new cards being added at roughly the rate that they expire, this
should be a reasonable solution.  A sample call is below:

  # Purge database of ecard records older than $DateLimit
  $Pg_daemon->purge_old_cards($path, $DateLimit, $card_name_file,
                              $name_passwd_file, $card_data_file
                              );

=item backup_db_purge_old()

This method is simply a combination of C<backup_db_files> and
C<purge_old_cards>.  It first makes a backup copy of every database
file with C<backup_db_files> and then it performs the purging of old
ecards with C<purge_old_cards>.  The arguments are identical with
C<purge_old_cards> as can be seen in the sample call below.


  # Backup and purge old records in one step.
  $Pg_daemon->backup_db_purge_old($path, $DateLimit, $card_name_file,
                                  $name_passwd_file, $card_data_file
                                 );

This method exists mainly to standardize calling schemes between the
application daemon and command line utilties.

=back

=head1 COPYRIGHT

Copyright (c) 2004-2005  Edouard Lagache

This software is released under the GNU General Public License, Version 2.
For more information, see the COPYING file included with this software or
visit: http://www.gnu.org/copyleft/gpl.html

=head1 BUGS

No known bugs at this time.

=head1 AUTHOR

Edouard Lagache <pgreetdev@canebas.org>

=head1 VERSION

1.0.0

=head1 SEE ALSO

syslog, L<Pgreet>, L<Pgreet::Config>, L<Pgreet::Error>, L<Log::Dispatch>,
L<Log::Dispatch::File>, L<Log::Dispatch::Syslog>, L<CGI::Carp>

=cut

1;
