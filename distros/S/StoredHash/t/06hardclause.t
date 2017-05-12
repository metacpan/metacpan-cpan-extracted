# Test for embedding "hard values" inside queries.
use Test::More;
use lib ('..');
use Data::Dumper;
use StoredHash;
use DBI;
use strict;
use warnings;

my $fmsg = "To run this test $0, install DBD::CSV - DBI Driver for CSV files.";

# Determine plan / skip according to DBD::CSV availability
SKIP: {
   #eval {require(DBD::CSV)};
   eval("use DBD::CSV;");
   if ($@) {plan(skip_all => "DBD::CSV Not available (not fatal, $fmsg)");}
};
plan('tests' => 10); # 7,9
# perldoc DBD::CSV
my $connstr = qq{DBI:CSV:csv_sep_char=\\;;csv_eol=\n;};
my $dbh = DBI->connect($connstr);
print("#$connstr#\n");
isa_ok($dbh, 'DBI::db');
can_ok($dbh, 'quote'); # , "DBI driver can quote"
setuptables($dbh);

my $sh = StoredHash->new('table' => 'anim', pkey => ['id'], 'dbh' => $dbh);
# id;name;description;family;lifespan
# 
my $h = {'id' => '6', 'name' => 'Bear', 'description' => 'Agressive Furry Animal',
  'family' => 'mammal', 'lifespan' => '30-40y'};
$h = {'id' => '7', 'name' => 'Kitty', 'description' => 'Thomas O\'Malley',
  'family' => 'mammal', 'lifespan' => '6-8y'};
{
   local $StoredHash::hardval = 2;
   my $id = $sh->insert($h);
   #ok($id, "Got ID for bear ($id)");
   #print("ID: $id\n");
   ok($id =~ /'Kitty'/, "Got Kitty within clause");
	
};
# Load all from anim.txt
my $arr = $sh->loadset();
{
  local $StoredHash::hardval = 2;
  map({
  	ok($sh->insert($_) =~ m/'$_->{'name'}'/, "Got name within clause ($_->{'name'})");
  } @$arr);
};
################# MISC ####################
#print(Dumper($h));
#print StoredHash::quote($h->{'description'});
ok(StoredHash::quote($h->{'description'}) eq "'Thomas O''Malley'", "Quoting matches expected");
my $id = $sh->fetchautoid();
#print("$id\n");

sub setuptables {
   my ($dbh) = @_;
   our $dir = (-f "anim.txt") ? "." : "t";
   my $fname = "$dir/anim.txt";
   if (!-f $fname) {die("No File $fname");}
   my $fname2 = "$dir/animfamily.txt";
   if (!-f $fname2) {die("No File $fname2");}
   $dbh->{'csv_tables'}->{'anim'} = {'file' => $fname};
   $dbh->{'csv_tables'}->{'animfamily'} = {'file' => $fname2};
}
