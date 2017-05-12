use Test::More ;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
use lib '..';

# Any StoredHash interface always requires to manage connection
# outside. Set conn params for ARS testing by (assuming bourne/bash/ksh shell)
# export ARS_SERVER=remedy-dev.company.com
# export ARS_USER=joears
# export ARS_PASS=hardtoguess
# export ARS_SCHEMA=HPD:HelpDesk
# Check by: env | grep ARS_
my @arsprops = ('ARS_SERVER','ARS_USER','ARS_PASS', 'ARS_SCHEMA', );
# doing require(ARS); would miss the imports/exports
# NOTE: This needs to be done outside
#my $arsloaded = 0; # = $@ ? 0 : 1;
#
#eval("use ARS;");
#if (!$@) {$arsloaded = 1;}
# Default to universal schema
if (!$ENV{'ARS_SCHEMA'}) {$ENV{'ARS_SCHEMA'} = 'HPD::Helpdesk';}
SKIP: {
   eval("use ARS;");
   note("Tried loading ARS");
   #!$arsloaded
   # use Config;$Config{archname}
   if ($@) {plan('skip_all', "ARS Module NOT found in the system. Check availability on your system ($^O)");exit(0);}
   if (!grep({$ENV{$_};} @arsprops)) {plan('skip_all', "one of environment vars @arsprops missing (Check all)");exit(0);}
};
plan(tests => 19); # 10,13,19
#NOT:
use_ok('ARS'); # Called second time just for namespace import/export
ok($ARS::VERSION, "Have ARS Module loaded ($ARS::VERSION)");

use_ok('StoredHash');
use_ok('StoredHash::ARS');

my $ctrl = ars_Login($ENV{'ARS_SERVER'}, $ENV{'ARS_USER'}, $ENV{'ARS_PASS'});
if (!$ctrl) {die("No Connection to Remedy (@ENV{'ARS_SERVER','ARS_USER',}, ..ARS_PASS..): $ars_errstr");}
ok($ctrl, "Got ARS/Remedy Connection");

isa_ok($ctrl, 'ARControlStructPtr');
# 'pkey' => [''],
my $shp = StoredHash::ARS->new('table' => $ENV{'ARS_SCHEMA'},  'dbh' => $ctrl, 'debug' => 0);
isa_ok($shp, 'StoredHash::ARS');
#DEBUG:print(Dumper($shp));
#DEBUG:print("$ctrl\n");
my $attrs = $shp->cols();
my $acnt = @$attrs;
ok(ref($attrs) eq 'ARRAY', "Attrs Were Returned from schema ($acnt)");
#ok($acnt > 5, "Multiple Attrs Returned from schema ($acnt)");
storetofile("/tmp/ars.attrs.$$.pl", Dumper($attrs));
sub storetofile {
  my ($tmpfile, $cont) = @_; # ;
  open(my $fh, ">", $tmpfile);
  print($fh $cont);
  close($fh);
  note("Dump written to '$tmpfile'");
}
# By default ONLY default fields are brought across
# ARS Built-in field 4 = 'Assignee Login Name'
my ($t1,$t2, $td);
################# Load set
$t1 = time();
# 4: Assignee Login Name
note("Load set 1) 4=$ENV{'USER'}, default fields");
my $filter = {'4' => $ENV{'USER'},};
# Note: This seems to return implied / default fields (not all)
my $arr = $shp->loadset($filter);
$t2 = time();
$td = ($t2-$t1);
my $uecnt = scalar(@$arr);
ok(ref($arr) eq 'ARRAY', "Result set for search is an ARRAY ($uecnt ents.)");
my $sampleid = $arr->[0]->{'1'};
ok($sampleid, "Got sample id: $sampleid (must sample early)");
#DEBUG:print(Dumper($arr)." Got ".scalar(@$arr)." ents. ($td seconds)\n");
storetofile("/tmp/ars.loadset1.$$.pl", Dumper($arr));

$t1 = time();
note("Load set 2) 4=$ENV{'USER'}, explicit fields (2 fields)");
# Select only 2 fields with an explicit list
$arr = $shp->loadset($filter, undef, 'attrs' => ['240000015', '200000003']);

$t2 = time();
$td = ($t2-$t1);
#DEBUG:print(Dumper($arr)." Got ".scalar(@$arr)." ents. ($td seconds)\n");
ok(ref($arr) eq 'ARRAY', "Result set for search (by limited attrs) is an ARRAY");
my $cnts2 = scalar(@$arr);
ok($cnts2 > 0, "Got Entries ($cnts2)");
storetofile("/tmp/ars.loadset2.$$.pl", Dumper($arr));
# NOTE: Not enough attrs to sample ID

#DEBUG:$shp->{'debug'} = 1;
############ Exists
note("Test exists()");
my $eok = $shp->exists([$sampleid]); # 'HD0000004253143'
ok($eok, "exists - ARS DB Has requested entry (with valid sample ID '$sampleid')");
my $eok2 = $shp->exists(['foobar']);
ok(!$eok2, "ARS DB Does not have the goofy entry (with invalid ID)");
############ Load ########
# Load single
note("Load (with and without explicit attrs) and check attributes");
my $e1 = $shp->load([$sampleid]);
ok(ref($e1) eq 'HASH', "Load - single entry1, implied fields by ID $sampleid from DB");
if ($ENV{'ARS_DEBUG'}) {print(Dumper($e1));}
storetofile("/tmp/ars.load1.$$.pl", Dumper($e1));
note("Test Attributes of entry1");
my $acnt1 = keys(%$e1);
ok($acnt1 > 10, "Got default attrs in entry1 ($acnt1)");
my $e2 = $shp->load([$sampleid], 'attrs' => ['1','5','8','240000015','200000012','536871006',]);
if (!$e2) {die("Could not get entry");}
my $acnt2 = keys(%$e2);
ok($acnt2 == 6, "Got explicit attrs in entry2 ($acnt2)");
if ($ENV{'ARS_DEBUG'}) {print(Dumper($e2));}
storetofile("/tmp/ars.load2.$$.pl", Dumper($e2));
# Load a set
# TODO: Test multiple scenarios with different 'attrs' settings.
my $lsfilter = {};
#my $arr = $shp->loadset($lsfilter); # NO attrs

######### MODS ########################
# Consider NOT running these on any prod database.
# Enable VERY Selectively. Not part of default read-only suite. 
my $e3 = {};
#my $arsid = $shp->insert($e3);
# 'Work Log' 240000008 (aka Diary)
my $e4 = {'240000008' => "This worktask has been completed",};
#my $okup = $shp->update($e4, [$sampleid]);
#ok($okup, "Entry $sampleid has been updated");
############# MISC #################
note("Misc tests");
eval {$shp->fetchautoid();};
ok($@, "Got exception on ARS fetchautoid() as expected");
$@ = undef;
my $inval = StoredHash::ARS::invalues(['foo','bar',]);
#print("$inval\n");
ok($inval eq '"foo","bar"', "WHERE-IN vals as expected");
if ($ctrl) {ars_Logoff($ctrl);}
############# ARS Meta ##################
use_ok("StoredHash::ARSMeta");
$shp->{'debug'} = 1;
my $arsmeta = StoredHash::ARSMeta::meta($shp); # 
ok($arsmeta, "Got information about Remedy Schema");
storetofile("/tmp/ars.meta1.$$.pl", Dumper($arsmeta));
