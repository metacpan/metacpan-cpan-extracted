use strict;
use warnings;
use Test::More tests => 16;
use Test::Deep;
use Text::CSV;

use lib qw(t/lib);

use ChoboTest::FakeHandle;

my $fake_dbh = ChoboTest::FakeHandle->new();


my $sth = $fake_dbh->prepare("select cvterm_id, name, cv_id from cvterm");
$sth->execute();
is ($sth->query_table_name(), 'cvterm');

my $row_1 = $sth->fetchrow_hashref();
cmp_deeply($row_1, { cvterm_id => 400, name => 'is_a', cv_id => 300 });
my $row_2 = $sth->fetchrow_hashref();
cmp_deeply($row_2, {'cvterm_id' => 401, 'name' => 'exact', 'cv_id' => 301});
my $row_3 = $sth->fetchrow_hashref();
cmp_deeply($row_3, {'cvterm_id' => 402, 'name' => 'narrow', 'cv_id' => 301});
my $row_4 = $sth->fetchrow_hashref();
cmp_deeply($row_4, {'cvterm_id' => 403, 'name' => 'cv_version', 'cv_id' => 302});
my $row_5 = $sth->fetchrow_hashref();
cmp_deeply($row_5, {'cvterm_id' => 404, 'name' => 'replaced_by', 'cv_id' => 303});
my $row_6 = $sth->fetchrow_hashref();
is($row_6, undef);


$fake_dbh->do('COPY db(name) FROM STDIN CSV');
$fake_dbh->pg_putcopydata("test_db\n");
$fake_dbh->pg_putcopyend();

$sth = $fake_dbh->prepare("select db_id, name from db");
is ($sth->query_table_name(), 'db');

$row_1 = $sth->fetchrow_hashref();
cmp_deeply($row_1, { db_id => 100, name => 'OBO_REL' });
$row_2 = $sth->fetchrow_hashref();
cmp_deeply($row_2, { db_id => 101, name => 'internal' });
$row_3 = $sth->fetchrow_hashref();
cmp_deeply($row_3, { db_id => 102, name => 'test_db' });
$row_4 = $sth->fetchrow_hashref();
is($row_4, undef);


$fake_dbh->do('COPY dbxref(accession, db_id) FROM STDIN CSV');
$fake_dbh->pg_putcopydata("test_dbref_1,101");
$fake_dbh->pg_putcopydata("test_dbref_2,101");
$fake_dbh->pg_putcopyend();


$sth = $fake_dbh->prepare("select dbxref_id, accession, db_id from dbxref");
is ($sth->query_table_name(), 'dbxref');

my @expected_dbxrefs = (
  { dbxref_id => 200, accession => 'is_a', db_id => 100 },
  { dbxref_id => 201, accession => 'exact', db_id => 101 },
  { dbxref_id => 202, accession => 'narrow', db_id => 101 },
  { dbxref_id => 203, accession => 'cv_version', db_id => 101 },
  { dbxref_id => 204, accession => 'replaced_by', db_id => 101 },
  { dbxref_id => 205, accession => 'test_dbref_1', db_id => 101 },
  { dbxref_id => 206, accession => 'test_dbref_2', db_id => 101 }
);

cmp_deeply([$sth->fetchrow_hashref(), $sth->fetchrow_hashref(), $sth->fetchrow_hashref(),
            $sth->fetchrow_hashref(), $sth->fetchrow_hashref(), $sth->fetchrow_hashref(),
            $sth->fetchrow_hashref()],
           \@expected_dbxrefs);
my $end_row = $sth->fetchrow_hashref();
is($end_row, undef);


$fake_dbh->do("COPY dbxref(dbxref_id, accession, db_id) TO STDOUT CSV") or die;

my @copy_ret_rows = ();
my $tsv = Text::CSV->new({sep_char => ","});
my $line = undef;

while ($fake_dbh->pg_getcopydata(\$line) > 0) {
  chomp $line;
  if ($tsv->parse($line)) {
    my @fields = $tsv->fields();
    push @copy_ret_rows, {
      dbxref_id => $fields[0],
      accession => $fields[1],
      db_id => $fields[2],
    };
  }
}

cmp_deeply(\@copy_ret_rows, \@expected_dbxrefs);
