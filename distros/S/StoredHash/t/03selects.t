#!/usr/bin/perl
# Test Loading sets (AoH) and individual entries (hashes)
# Depends on DBI CSV file driver (DBD::CSV)
# On Ubuntu/Debian system install package 'libdbd-csv-perl'
use Test::More;
use Data::Dumper;
use DBI;
use lib('..');
use StoredHash;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
use strict;
use warnings;
our $dbh;

my $fmsg = "To run this test $0, install DBD::CSV - DBI Driver for CSV files.";
#my $dlf = 0;

# Determine plan / skip according to DBD::CSV availability
SKIP: {
   eval("use DBD::CSV;");
   if ($@) {plan(skip_all => "DBD::CSV Not available (not fatal to complete remaining tests, $fmsg)");}
   eval("use Storable;");
   if ($@) {plan(skip_all => "Module 'Storable' Not available (not fatal to complete remaining tests)");}
   if (!Test::More->can('is_deeply')) {plan('skip_all', "Test::More cannot compare deep data structures !");}
};
plan('tests', 19); # 5,8,14,16,19
note("Check DBD::CSV Version and connect()");
ok($DBD::CSV::VERSION, "Have DBI:CSV loaded ($DBD::CSV::VERSION)");
#$dbh = DBI->connect("c:f_dir=t");
$dbh = DBI->connect(qq{DBI:CSV:csv_sep_char=\\;;csv_eol=\n;});
$dbh or die "Cannot connect: " . $DBI::errstr;
ok($dbh, "Got DBI Connection");
note("Setup (CSV) tables");
setuptables($dbh);

my $sh = StoredHash->new('table' => 'anim', pkey => ['id'], 'dbh' => $dbh);
my $cols = $sh->cols();
if (!$cols || !@$cols) {die("No Columns");}
my $colcnt = scalar(@$cols);
ok(ref($cols) eq 'ARRAY', "Got Columns ($colcnt)");
my $arr = $sh->loadset();
#DEBUG:print(Dumper($arr));
ok (ref($arr) eq 'ARRAY', "Got a set of All Entries (no filter, no sorting, all fields)");
my $ecnt = $sh->count();
ok($ecnt, "Got Entry count ($ecnt)");
# 
my $e = $sh->load([2]);
#print(Dumper($e));
ok (ref($e) eq 'HASH', "Got an Entry (by ID:2)");
ok($e->{'id'} == 2, "ID (2) Really matches (by direct access to entry)");
# Low level
note("Test low level access w. internal API");
my @ids = $sh->pkeyvals($e);
ok(@ids == 1, "Entry Has single (non-composite) ID value");
ok($ids[0] == 2, "ID Value (2) matches as extracted by pkeyvals()");
#$sh->{'debug'} = 1;
note("Load Misc result sets");
$arr = $sh->loadset({'description' => '%Fur%',});
{
local $sh->{'dbh'} = undef;
#my $q = $sh->loadset({'description' => '%Fur%',});
#ok($q =~ /LIKE/, "Generated LIKE-query");
}
ok(@$arr == 2, "Got 2 Furry Animals");
# Should get same by count()
my $furcnt = $sh->count({'description' => '%Fur%',});
ok($furcnt == 2, "Got same count ($furcnt) by count()");
$arr = $sh->loadset({'family' => 'mammal',}, ['name']);
ok (ref($arr) eq 'ARRAY', "Got a Filtered set of Entries");
ok(@$arr == 4, "Got 4 Mammals, Sorted by name");
my $arrdup = Storable::dclone($arr);
# Perl-sort the copy
@$arrdup = sort({$a->{'name'} cmp $b->{'name'};} @$arrdup);
#DEBUG:print(Dumper($arr, $arrdup));
is_deeply($arr, $arrdup, "Came sorted correctly from StoredHash (by deep comparison)");
note("Load and sort by multiple cols, select partial fields");
$arr = $sh->loadset({'family' => 'mammal',}, ['name','family'], 'attrs' => ['name','family']);
my $max = 0;
map({my $kcnt = scalar(keys(%$_));if ($kcnt > $max) {$max = $kcnt;};} @$arr);
ok($max == 2, "Got 2 cols (as partial fields select)");
#print(Dumper($arr));
############### MISC #####################

# Tap as class methods invalues() and 
my $wiq = StoredHash::invalues(['mammal','reptile',]);
ok(!ref($wiq), "Got WHERE IN value list as scalar string");
$wiq =~ s/\s//g;
ok($wiq eq "'mammal','reptile'", "WHERE IN value list matches expected");
#print($wiq);
my $rf = StoredHash::rangefilter('id', [1,3]);
ok($rf && !ref($rf), "Generated range filter");
#print($rf);
my $looksok = $rf =~ /\bid\b/ && $rf =~ /AND/ && $rf =~ /\b1\b/ && $rf =~ /\b3\b/;
ok($looksok, "Range filter looks correct: $rf");
# Auto-swapping
$rf = StoredHash::rangefilter('id', [3,1]);



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
