use strict;
use warnings;
use DBI;
use Module::CoreList::DBSchema;

$|=1;

my $dbh = DBI->connect('dbi:SQLite:dbname=corelist.db','','') or die $DBI::errstr;
$dbh->do(qq{PRAGMA synchronous = OFF}) or die $dbh->errstr;

my $mcdbs = Module::CoreList::DBSchema->new();

# create tables

my %tables = $mcdbs->tables();

print "Creating tables ... ";

foreach my $table ( keys %tables ) {
  my $sql = 'CREATE TABLE IF NOT EXISTS ' . $table . ' ( ';
  $sql .= join ', ', @{ $tables{$table} };
  $sql .= ' )';
  $dbh->do($sql) or die $dbh->errstr;
  $dbh->do('DELETE FROM ' . $table) or die $dbh->errstr;
}

print "DONE\n";

# populate with data

my $data = $mcdbs->data();

print "Populating tables ... ";

$dbh->begin_work;

foreach my $row ( @{ $data } ) {
  my $sql = shift @{ $row };
  my $sth = $dbh->prepare_cached($sql) or die $dbh->errstr;
  $sth->execute( @{ $row } ) or die $dbh->errstr;
}

$dbh->commit;

print "DONE\n";

# done
