#!/usr/bin/perl -w -T
# -*- cperl -*-

our $debug = 1; $|++; use Data::Dumper; # For testing purposes.

our %config =
  (
   storedir   => '/home/mailproxy/store',        # Directory where stuff is stored.  The user specified
                                                 # by sysaccount needs read/write privileges here.
   server     => 'postoffice.brightchoice.com',  # Where to get mail from, probably your ISP's mail server.
   serverdel  => 1,                              # Set serverdel to 1 to delete mail from server
                                                 # once stored (untested).  If undef, mail is left
                                                 # on server (untested).  Set serverdel to 0 to
                                                 # delete mail from server only once it has been
                                                 # retrieved by a client.
   storedel   => undef,                          # Set storedel to 1 to delete mail from store once
                                                 # retrieved by client (untested).  If undef, mail
                                                 # is archived.  Note that certain combinations will
                                                 # result in weird behavior; for example, if you set
                                                 # serverdel to undef and storedel to 1, the client
                                                 # may keep getting copies of each message
                                                 # repeatedly forever.
   polldelay  => 600,                            # Number of seconds to delay between rounds of
                                                 # checking the server.  Does not have to be an
                                                 # integer.  Low values of this will pester the mail
                                                 # server continuously, so be aware of bandwidth and
                                                 # performance issues and your ISP's policies.
   sysaccount => 'mailproxy',                    # Account on the system that we run as while talking
                                                 # to the users.  This account must have read/write
                                                 # privs on the storedir, and preferably nowhere else
                                                 # that matters.  TODO: make the poller run as this
                                                 # account also.
   sysgroup   => 'nobody',                       # Group on the system that we run as.
   log_level  => 3,                              # Log level for Net::Server
   authretr   => 0,                              # Set this to a true value to check for new mail
                                                 # on the spot when authenticating (untested), false
                                                 # to just use what's already stored.
   archiver   => ':archive',                     # Username suffix that magically accesses the user's
                                                 # archive (i.e., causes already retrieved messages to
                                                 # be offered again).  User postpends a number to this
                                                 # suffix indicating how many times a message can have
                                                 # been retrieved and still be offered.  Note that
                                                 # setting storedel true will make archiver _mostly_
                                                 # useless, but the user can still use it with a value
                                                 # of 0 to authenticate by the password stored in the
                                                 # database e.g. when the real POP3 server is down, or
                                                 # if the user wants to avoid waiting for the real
                                                 # POP3 server (e.g. dialup users can reduce latency).
   maxboxsize  => 200,                           # Maximum number of messages to serve out per session.
                                                 # High values for this may cause weird bugs I haven't
                                                 #    tracked down yet to rear their ugly heads.
   # If you want to use MySQL instead of SQLite:
   dbd        => 'MySQL',                        # Set this to 'MySQL' to use MySQL (default is SQLite).
   mysqldb    => 'gplproxy',                     # Name of database to use in MySQL.
   mysqluser  => 'gplproxy',                     # MySQL username with privileges on that database.
   mysqlpass  => 'password',                     # MySQL password for that user.
   mysqlhost  => 'localhost',                    # Host where the MySQL db lives.
  );

use strict; use warnings; # I normally don't make all my code do this,
                          # but this code might end up on the
                          # CPAN and be seen by other people :-)

# You're now looking under the hood and should probably know Perl if
# you want to change much of anything below this point.  The truly
# user-serviceable stuff is above.

use Net::Server::POP3; # This handles the server half of the protocol, for talking to clients.
use Mail::POP3Client;  # This handles the client half of the protocol, for talking to servers.
use DateTime; use DateTime::Format::Mail; # retrieve uses these to insert a Received: header.
use DBI; # You also need DBD::SQLite installed, or else you have to change the db:: stuff to use a
         # different DBD module (e.g., DBD::mysql).  The db::handle routine would need to be changed
         # as well as the line in db::addrecord that gets the id of the record that was inserted.

for my $r (db::getrecord('mail_for_jonadab')) {
  $$r{UIDL} =~ s/\s*$//;
  db::updaterecord('mail_for_jonadab', $r);
}

# ------------------------------------------------------------------------------------------
#                                      DATABASE STUFF
# ------------------------------------------------------------------------------------------

package db;

# ADD:     $result  = db::addrecord(tablename, $record_as_hashref);
# UPDATE:  @changes = @{db::updaterecord(tablename, $record_as_hashref)};
# GET:     %record  = %{db::getrecord(tablename, id)};
# GETALL:  @records =   db::getrecord(tablename);     # Not for enormous tables.
# FIND:    @records = db::findrecord(tablename, fieldname, exact_value);
# DELETE:  $result  = db::delrecord(tablename, id);

# To ensure that a table exists (or if not create it):
# TABLE:   $result  = table(tablename, fieldname => type, fieldtwo => type, ...);

our $added_record_id;

sub handle {
  warn "[new handle]" if $main::debug>2;
  my $dbh;
  if ($main::config{dbd} eq 'MySQL') {
    $dbh =  DBI->connect("DBI:mysql:database=$main::config{mysqldb};host=$main::config{mysqlhost}",
                         $main::config{mysqluser}, $main::config{mysqlpass}, {'RaiseError' => 1});
    #$dbh->prepare("use $main::config{mysqldb}")->execute();
  } else {
    my $dbfile = "$main::config{storedir}/gplproxy.maildb.dat";
    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","") or die "Cannot Connect: $DBI::errstr\n$@\t$!\n";
    $dbh->{sqlite_handle_binary_nulls}=1;
  }
  return $dbh;
}

sub now {
  my $now;
  if ($main::config{dbd} eq 'MySQL') {
    use DateTime::Format::MySQL;
    $now = DateTime::Format::MySQL->format_datetime(DateTime->now());
  } else {
    $now = DateTime::Format::Mail->format_datetime(DateTime->now());
  }
  return $now;
}

sub getrecord {
  # GET:     %record  = %{getrecord(tablename, id)};
  # GETALL:  @recrefs = getrecord(tablename);     # Don't use this way on enormous tables.
  my ($table, $id, $q) = @_;
  die "Too many arguments: getrecord(".(join', ',@_).")" if $q;
  my $db = handle();
  $q = $db->prepare("SELECT * FROM $table".(($id)?" WHERE id = '$id'":""));  $q->execute();
  my @answer; my $r;
  while ($r = $q->fetchrow_hashref()) {
    if (wantarray) {
      push @answer, $r;
    } else {
      return $r;
    }
  }
  return @answer;
}

sub delrecord {
  # DELETE:  $result  = delrecord(tablename, id);
  my ($table, $id, $q) = @_;
  die "Too many arguments: getrecord(".(join', ',@_).")" if $q;
  my $db = handle();
  $q = $db->prepare("DELETE FROM $table WHERE id=?");
  return $q->execute($id);
}

sub changerecord {
  # Used by updaterecord.  Do not call directly; use updaterecord instead.
  my ($table, $id, $field, $value) = @_;
  my $db = handle();
  my $q = $db->prepare("update $table set $field=? where id='$id'");
  return $q->execute($value);
}

sub updaterecord {
# UPDATE:  @changes = @{updaterecord(tablename, $record_as_hashref)};
# See end of function for format of the returned changes arrayref
  my ($table, $r, $f) = @_;
  die "Too many arguments: updaterecord(".(join', ',@_).")" if $f;
  my %r = %{$r};
  my %o = %{getrecord($table, $r{id})};
  my @changes = ();
  foreach $f (keys %r) {
    if ($r{$f} ne $o{$f}) {
      my $result = changerecord($table, $r{id}, $f, $r{$f});
      push @changes, [$f, $r{$f}, $o{$f}, $result];
    }
  }
  return \@changes;
  # Each entry in this arrayref is an arrayref containing:
  # [ field changed, new value, old value, result ]
}

sub addrecord {
# ADD:     $result  = addrecord(tablename, $record_as_hashref);
  my ($table, $r, $f) = @_;
  die "Too many arguments: addrecord(".(join', ',@_).")" if $f;
  my %r = %{$r};
  my $db = handle();
  my ($result,$q);
  if ($main::config{dbd} eq 'MySQL') {
    my @clauses = map { "$_=?" } sort keys %r;
    my @values  = map { $r{$_} } sort keys %r;
    $q = $db->prepare("INSERT INTO $table SET ". (join ", ", @clauses));
    $result = $q->execute(@values);
  } else {
  # But for SQLite we require a different syntax:
    $q = $db->prepare("INSERT INTO $table (".
                      (join ", ", sort grep { defined $r{$_} } keys %r)
                      .") VALUES (".
                      (join ", ", map {"?"} grep { defined $r{$_} } keys %r)
                      .")");
    $result = $q->execute(map { $r{$_} } sort grep { defined $r{$_} } keys %r);
  }
  $result or warn "Cannot add record: " . $db->errstr . (($main::config{dbd}eq'MySQL')?("(".$db->{mysql_error}.")"):"") . " [[" . (Dumper(\%r)) . "]]" if defined $main::debug;
  $added_record_id = ($main::config{dbd} eq 'MySQL') ? $q->{mysql_insertid} : $db->func('last_insert_rowid');
  return $result;
}

sub findrecord {
# FIND:    @records = findrecord(tablename, fieldname, exact_value);
  my ($table, $field, $value, $q) = @_;
  die "Too many arguments: getrecord(".(join', ',@_).")" if $q;
  my $db = handle();
  $q = $db->prepare("SELECT * FROM $table WHERE $field=?");  $q->execute($value);
  my @answer; my $r;
  while ($r = $q->fetchrow_hashref()) {
    if (wantarray) {
      push @answer, $r;
    } else {
      return $r;
    }
  }
  return @answer;
}

# I have not tested searchrecord with DBD::SQLite and have commented
# it out, since gplproxy.pl doesn't need it. Uncomment and try it if
# you need it.  The function (and all this db stuff) was originally
# written for a MySQL-based CGI thingy.  Of course you can always call
# db::handle directly and do custom SQL commands.

# sub searchrecord {
# # SEARCH:  @records = @{searchrecord(tablename, fieldname, value_substring)};
#   my ($table, $field, $value, $q) = @_;
#   die "Too many arguments: getrecord(".(join', ',@_).")" if $q;
#   my $db = handle();
#   $q = $db->prepare("SELECT * FROM $table WHERE $field LIKE '%$value%'");  $q->execute();
#   my @answer; my $r;
#   while ($r = $q->fetchrow_hashref()) {
#     if (wantarray) {
#       push @answer, $r;
#     } else {
#       return $r;
#     }
#   }
#   return @answer;
# }

sub table {
  # To ensure that a table exists (or if not create it):
  # TABLE:   $result  = addtable(tablename, fieldname => type, fieldtwo => type, ...);
  # It is NOT necessary to include the id field; this will be added automagically.
  my ($tablename, %fieldtype) = @_;
  my $db = handle();
  my $ifne = ($main::config{dbd} eq 'MySQL') ? "IF NOT EXISTS" : "";
  my $idtype = ($main::config{dbd} eq 'MySQL') ? "integer NOT NULL AUTO_INCREMENT PRIMARY KEY" : "INTEGER PRIMARY KEY";
  my $q = $db->prepare("CREATE TABLE $ifne $tablename ( id $idtype, "
                       . (join ", ", map {"$_ $fieldtype{$_}"} keys %fieldtype ) . ")" );
  my $result = $q->execute();
  warn "Table creation result: $result" if $main::debug;
}
