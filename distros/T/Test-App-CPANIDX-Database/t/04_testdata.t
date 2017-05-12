use strict;
use warnings;
use Test::More;
use DBI;
use File::Temp qw[tempdir];
use Test::App::CPANIDX::Database;

my $time = time();

my $tmpd = tempdir( DIR => '.', CLEANUP => 1 );

my $tests = [
    [ 'auths', 'FOOBAR', 'Foo Bar', 'foobar@cpan.org' ],
    [ 'mods',  'Foo::Bar','Foo-Bar','0.01','FOOBAR','0.01' ],
    [ 'dists', 'Foo-Bar','FOOBAR','F/FO/FOOBAR/Foo-Bar-0.01.tar.gz','0.01' ],
    [ 'timestamp', $time, $time ],
];

plan tests => scalar @{ $tests };

my $tdb = Test::App::CPANIDX::Database->new( dir => $tmpd, time => $time );
my $dbfile = $tdb->dbfile;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile",'','') or die $DBI::errstr;

foreach my $datum ( @{ $tests } ) {
  my $table = shift @{ $datum };
  my $sth = $dbh->prepare(qq{SELECT * FROM $table}) or die $dbh->errstr;
  $sth->execute();
  my $row = $sth->fetchrow_arrayref();
  is_deeply( $row, $datum, qq{The row for '$table' is okay} );
}
