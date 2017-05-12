#!/usr/bin/perl -w
# -*- cperl -*-

# gplproxy.pl is Copyright 2004, Galion Public Library.  Written by Nathan Eady for library
# purposes, this code is released with NO WARRANTY under the same terms as Net::Server::POP3
# Note that in this code the letters GPL (or gpl) always stand for Galion Public Library.

# This is gplproxy.pl version 0.0001

# This code is in alpha stage, may be incomplete, and has received very little testing; it will
# probably not work entirely as desired and MAY lose mail (though I hope not), contain security
# flaws, or cause other issues.  Caveat user.  Please perform a full security audit on this code
# before deploying it in a production environment.  (Bug reports are welcome.)

our $debug = 1; $|++; use Data::Dumper; # For testing purposes.

my %config =
  (
   storedir   => '/home/mailproxy/store',        # Directories where sqlite stuff is stored.
                                                 # (MySQL stuff is of course stored in the
                                                 # usual place.)
   mysqldb    => 'gplproxy',                     # Name of database to use in MySQL.
   mysqluser  => 'gplproxy',                     # MySQL username with privileges on that database.
   mysqlpass  => 'password',                     # MySQL password for that user.
   mysqlhost  => 'localhost',                    # Host where the MySQL db lives.
  );

use strict; use warnings; # I normally don't make all my code do this,
                          # but this code might end up on the
                          # CPAN and be seen by other people :-)

use DBI; use DateTime::Format::Mail; use DateTime::Format::MySQL; my $dotcount;

my $dbfile = "$config{storedir}/gplproxy.maildb.dat";
my $sqlite = DBI->connect("dbi:SQLite:dbname=$dbfile","","") or die "Cannot Connect: $DBI::errstr\n$@\t$!\n";
$sqlite->{sqlite_handle_binary_nulls}=1;

my $mysql = DBI->connect("DBI:mysql:database=$config{mysqldb};host=$config{mysqlhost}",
                         $config{mysqluser}, $config{mysqlpass}, {'RaiseError' => 1})
  or die ("Cannot Connect to MySQL: $DBI::errstr\n");

$mysql->prepare("CREATE TABLE users ( id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT, username mediumtext, password mediumtext, nopoll integer)")->execute();

my $userquery = $sqlite->prepare("SELECT * FROM users");
$userquery->execute();
my $urec;
while ($urec = $userquery->fetchrow_hashref()) {
  print "\n\nProcessing user $$urec{username}";
  my $usub = $mysql->prepare("INSERT INTO users SET " . (join ", ", map { "$_=?" } sort keys %$urec));
  $usub->execute(map { $$urec{$_} } sort keys %$urec);
  my $username = $$urec{username};
  $mysql->prepare("CREATE TABLE mail_for_$username ( id integer NOT NULL PRIMARY KEY AUTO_INCREMENT,
                         UIDL mediumtext, stored datetime, retrieved integer, size integer, message longtext)")->execute();
  my $msgquery = $sqlite->prepare("SELECT * FROM mail_for_$username");
  $msgquery->execute();
  my $mrec;
  while ($mrec=$msgquery->fetchrow_hashref()) {
    print "."; ++$dotcount;
    print " $dotcount\n" if not ($dotcount % 60);
    $$mrec{size} ||= length $$mrec{message};
    $$mrec{stored} = DateTime::Format::MySQL->format_datetime(DateTime::Format::Mail->parse_datetime($$mrec{stored}));
    my $msgsub = $mysql->prepare("INSERT INTO mail_for_$username SET " . (join ", ", map {"$_=?"} sort keys %$mrec));
    $msgsub->execute(map { $$mrec{$_}} sort keys %$mrec);
  }
}
print "\n\nDone.\n";
