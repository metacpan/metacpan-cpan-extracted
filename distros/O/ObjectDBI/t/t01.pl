
use lib '../lib';
use ObjectDBI;
use DBD::CSV;
use Data::Dumper;

sub no_test {
  print "1..1\nok 1 Skipped # SKIP No database available\n";
  exit;
}

my $dir = "/tmp/dbd_csv";

`rm -rf $dir`;
mkdir $dir || no_test();

my $dbh = DBI->connect("dbi:CSV:", "", "", {
  f_dir => $dir
}) || no_test();

my $seq = 1;
sub seq {
  return $seq++;
}

my $objectdbi = ObjectDBI->new(
  dbh => $dbh,
  sequencefnc => 'main::seq',
#  debug => 1,
) || no_test();

$objectdbi->get_dbh()->do("
  create table perlobjects (
    obj_id integer,
    obj_pid integer,
    obj_gpid integer,
    obj_name char(255),
    obj_type char(255),
    obj_value char(255)
  )
");

my $hash = { foo => [ 'bar' ] };
$hash->{'foobar'} = $hash->{foo};
my $str1 = Dumper($hash);
my $id = $objectdbi->put($hash);
my $ref = $objectdbi->get($id); 
my $str2 = Dumper($ref);
print "1..1\n";
if ($str1 eq $str2) {
  print "ok 1\n";
} else {
  print "not ok 1\n";
}

$objectdbi->get_dbh()->do("drop table perlobjects");

$dbh->disconnect();

`rm -rf $dir`;

1;
