#!perl

use Test::More;

BEGIN {
    plan skip_all => 'set ENV TEST_ORDB_UNIHAN to continue'
      unless $ENV{TEST_ORDB_UNIHAN};
    plan tests => 4;
}

use ORDB::Unihan '-DEBUG';

my $sqlite_path = ORDB::Unihan->sqlite_path();
diag("debug $sqlite_path");
ok( -e $sqlite_path );

my @vals = ORDB::Unihan::Unihan->select( "where hex = ?", 3402 );
my ($TotalStrokes) = grep { $_->type eq 'TotalStrokes' } @vals;
ok($TotalStrokes);
is( $TotalStrokes->val, 6 );

my $dbh = ORDB::Unihan->dbh;
my $sql = 'SELECT val FROM unihan WHERE hex = 3402 AND type="RSUnicode"';
my $sth = $dbh->prepare($sql);
$sth->execute();
my ($val) = $sth->fetchrow_array;
is $val, 1.5;

1;
