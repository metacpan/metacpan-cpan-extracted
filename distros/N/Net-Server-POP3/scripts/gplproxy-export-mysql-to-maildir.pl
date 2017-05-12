#!/usr/bin/perl -w -T
# -*- cperl -*-

# Exports the mail from MySQL to a mail directory.  (Gnus can then
# read the mail as a directory group and respool it or whatever.
# Other apps may support mail directories also.)

my $user = "jonadab";   # Whose mail do we want?
my $dest = "/tmp/mail"; # Where do we want to put it?

use File::Spec;
use DateTime;
use DateTime::Format::Mail;

our $debug = 1; $|++; use Data::Dumper; # For testing purposes.

my %config =
  (
   mysqldb    => 'gplproxy',                     # Name of database to use in MySQL.
   mysqluser  => 'gplproxy',                     # MySQL username with privileges on that database.
   mysqlpass  => 'password',                     # MySQL password for that user.
   mysqlhost  => 'localhost',                    # Host where the MySQL db lives.
  );

use DBI; use DateTime::Format::Mail; use DateTime::Format::MySQL; my $dotcount;

my $mysql = DBI->connect("DBI:mysql:database=$config{mysqldb};host=$config{mysqlhost}",
                         $config{mysqluser}, $config{mysqlpass}, {'RaiseError' => 1})
  or die ("Cannot Connect to MySQL: $DBI::errstr\n");

my $q = $mysql->prepare("SELECT * FROM mail_for_$user");
$q->execute();
while (my $m = $q->fetchrow_hashref()) {
  print "Processing message $$m{id}\n";
  open MSG, ">".File::Spec->catfile($dest,$$m{id});
  my $now = DateTime::Format::Mail->new()->format_datetime(DateTime->now());
  print MSG "Received: From GPLProxy by export to maildir ($dest); $now\n";
  print MSG "X-GPLProxy-UIDL: $$m{UIDL}\n";
  print MSG "X-GPLProxy-Stored: $$m{stored}\n";
  #print MSG "X-GPLProxy-Retrieved: $$m{retrieved}\n";
  #print MSG "X-GPLProxy-Size: $$m{size}\n";
  print MSG $$m{message};
  close MSG;
}
