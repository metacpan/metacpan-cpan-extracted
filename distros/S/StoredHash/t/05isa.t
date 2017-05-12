#use Test::Simple tests => 3;
# TODO: Test ISA Functionality
use Test::More; #OLD: tests => 3;
use lib ('..', 't');
use StoredHash;
use Data::Dumper;
use strict;
use warnings;
use Storable;
use Scalar::Util ('reftype','blessed');
# Do this test with SQLite - if not avail skip all
eval("use DBD::SQLite;");
my $os = $^O;
# tested to work on a system w/o DBD::SQLite
if ($@) {plan('skip_all', "DBD::SQLite not available in your system (os:$os) !");}
# Choose DB path per OS (keep trailing slash to prevent choosing right slash later)
my $dbpath = $os =~ /win/i ? "c:\\temp\\" : "/tmp/";
my $testdbname = "$dbpath"."animdb.$$.sqlite"; # Create in local dir (or /tmp)
my $testdsn = "dbi:SQLite:dbname=$testdbname";
my $ook = open(my $fh, ">", $testdbname);
if (!$ook) {plan('skip_all', "OS temporary path ($dbpath) in your system (os:$os) !");}
############ PLAN #######
plan('tests', 21); # 8,11,20,21
ok($ook, "OS Temp area writeable (for testing)");
# Print to file to test ?: print($fh "Junk to wipe out");
close($fh);

# Must unlink test file for actual SQLite file
if (-f $testdbname) {unlink($testdbname);}
my $dbh = DBI->connect($testdsn, '','');
ok($dbh, "Got connection ($dbh)");
isa_ok($dbh, 'DBI::db', "... of proper DBI type:"); # 

{
   package Animal;
   our $shp;
   # MUST Reside within a BEGIN
   BEGIN {
     $Animal::shp = {'table' => 'anim', 'pkey' => ['id'], 'autoid' => 1,};
   };
   use StoredHash::ISA;
   use base ('StoredHash::ISA');
   sub createschema {
      my ($dbh) = @_;
      my $sql = <<EOT;
CREATE TABLE  IF NOT EXISTS anim (
  id INTEGER NOT NULL, name CHAR(16) NOT NULL, description CHAR(64),family CHAR(16) NOT NULL, lifespan CHAR(10),
  PRIMARY KEY(id)
)
EOT
      my $ok = $dbh->do($sql);
      if (!$ok) {die("Could not create schema: ".$dbh->errstr());}
      return(1);
   }
};
note("Populate schema");
my $oks = Animal::createschema($dbh);
ok($oks, "Schema created (on DB: '$testdbname')");


# Local Persister Config WITH class / blessing info
# Keep to prepopulate DB
my $shpc = {'table' => 'anim', 'pkey' => ['id'], 'class' => 'Animal', 'dbh' => $dbh};
# OR (Use Animal inherited persistance):
$Animal::shp->{'dbh'} = $dbh;
# TODO: Create reference file anim_data.pl to be used for population AND deep compare
# Create this statically with features of 03selects.t
#LOAD:
my $animarr = require("anim_data.pl");
ok(ref($animarr), "Got Animal data (Perl)");
my $icnt = scalar(@$animarr);
my $ocnt = scalar( grep({ref($_) eq 'HASH';} @$animarr) );
ok($ocnt == $icnt, "All ($icnt) are Hashes"); # Check all are hashes
# BLESS: ?
map({bless($_, 'Animal');} @$animarr);
my $bcnt = scalar( grep({blessed($_) eq 'Animal';} @$animarr) );
ok($bcnt == $icnt, "All ($icnt) are Animal after blessing collection.");
#DEBUG:print(Dumper($animarr));exit(0);
# Use local persister OR Animal class-method ? Or instance method ?
#map({$shp->insert($_);} @$animarr);
# OR:
my $okins = 0;
map({
   #print(Dumper($_));
   my $id = $_->insert();
   if ($id) {$okins++;}
   else {note("Failed to insert: $_->{'id'}");}
} @$animarr);
ok($okins, "Inserts by StoredHash::ISA ok ($okins inserts to '$testdbname')");
my $okupd = 0;
map({
  # Plain StoredHash update "delta" would look like this
  #my $delta = {'description' => "$_->{'description'} - at least it seems so for animal # $_->{'id'} "};
  # Using StoredHash::ISA we will more likely change object internal state
  $_->{'description'} = "$_->{'description'} - at least it seems so for animal # $_->{'id'} ";
  #TEMP:local $Animal::shp->{'dbh'} = undef; # Suppress connection (to get SQL)
  # Update 'description' only (use 'attrs')
  my $ok = $_->update([$_->{'id'}], 'attrs' => ['description']);
  #print("SQL:".$ok."\n");
  $okupd += $ok;
} @$animarr);
ok($okins, "Updates by StoredHash::ISA ok ($okins updates to '$testdbname')");
# Duplicate original entries (with new id) py doing partial insert
$okins = 0; # Reset
$animarr = do("anim_data.pl"); # Reload
map({bless($_, 'Animal');} @$animarr); # Re-bless
my $anicnt = scalar(@$animarr);
ok ($anicnt > 0, "Have something to insert ($anicnt)");
note("Insert ISA Animal:s");
map({
   #print(Dumper($_));
   my $id = $_->insert('attrs' => ['name','description','family','lifespan']);
   if ($id) {$okins++;}
   else {note("Failed to insert: $_->{'id'}");}
   note("Inserted ID: $id");
} @$animarr);
ok($okins, "Duplicate Inserts (w/o ID) by StoredHash::ISA ok ($okins inserts to '$testdbname')");



##### Load ###########
my $e = Animal->load([3]);
ok(reftype($e) eq 'HASH', "Load - Got an IS-A-HASH entry ($e)");
ok(ref($e) eq 'Animal', "Loaded Object is Animal");
my $eorg = Storable::dclone($e);
my $anim = $e->reload([3]);
is_deeply($eorg, $anim, "Reloaded (explicit id) OK (deeply)");
# Rely on internal ID
$anim = $e->reload();
is_deeply($eorg, $anim, "Reloaded (using internal id) OK (deeply)");
# Loadset, compare
note("Loadset tests");
my $shp = StoredHash->new(%$shpc);
ok($shp, "Instantiated barebones StoredHash persister");
$animarr = $shp->loadset(); # do("anim_data.pl"); # Reload
map({bless($_, 'Animal');} @$animarr); # Rebless
ok($animarr, "Loaded and (manually) blessed a set");
my $animarr2 = Animal->loadset();
ok($animarr2, "Load auto-blessed set with Animal->loadset()");
is_deeply($animarr, $animarr2, "Compared identical to original set (deeply)");
my $does = Animal->exists([3]);
ok($does, "Animal id=3 expected and found to exist");
$does = Animal->exists([333]);
ok(!$does, "Animal id=333 NOT expected and NOT found to exist");
