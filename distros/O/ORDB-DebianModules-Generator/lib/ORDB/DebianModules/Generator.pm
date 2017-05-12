package ORDB::DebianModules::Generator;

use Debian::ModuleList;
use DBI;

our $VERSION = '0.02';

sub save {
  my $file = shift;
  my @list = Debian::ModuleList::list_modules();
  unlink($file) if(-f $file);
  my $dbh = DBI->connect("dbi:SQLite:dbname=" . $file,"","");
  $dbh->do("CREATE TABLE debian_module ( module TEXT NOT NULL PRIMARY KEY );");
  $sth = $dbh->prepare("INSERT INTO debian_module (module) VALUES (?);");
  $sth->execute($_) foreach(@list);
  $sth->finish();
  $dbh->do("CREATE INDEX debian_module__module on debian_module ( module );");
  $dbh->disconnect;
}

=head1 NAME

ORDB::DebianModules::Generator - generator for the database ORDB::DebianModules points to

=cut

1;
