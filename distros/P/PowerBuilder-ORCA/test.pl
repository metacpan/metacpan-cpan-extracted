# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
BEGIN { plan tests => 33 };
use PowerBuilder::ORCA qw/:const/;
ok(1);
#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use Data::Dumper;
use Cwd;

my $cwd=cwd."\\";
$cwd=~s{/}{\\}g;
my $rc;

PowerBuilder::ORCA::LoadDll();
print "Using: $PowerBuilder::ORCA::ORCA_Dll\n";
ok(1);

my $ver;
my $subver;
if ( $PowerBuilder::ORCA::ORCA_Dll =~ /(.)(.)\.[^.]+$/ ) {
	$ver = hex($1);
	$subver = hex($2);
	printf "PowerBuilder version %d.%d\n",$ver,$subver;
} else {
	ok(0);
}

#################################################
# new
#################################################
my $ses=new PowerBuilder::ORCA([$cwd.'orca_test.pbl',
	$cwd.'orca_test2.pbl'],
	$cwd.'orca_test.pbl',
	'orca_test'
);
ok($ses);

#################################################
# EntryInfo, GetError
#################################################
my %h;
$rc=$ses->EntryInfo("orca_test.pbl","orca_test2",PBORCA_APPLICATION,\%h);
ok($rc==-3 && $ses->GetError() eq "'orca_test2' was not found");
$rc=$ses->EntryInfo("orca_test.pbl","orca_test",PBORCA_APPLICATION,\%h);
#print join(":",%h)."\n";
ok(!$rc && exists($h{SourceSize}));

#################################################
# Export
#################################################
my $buf;
$rc=$ses->Export("orca_test2.pbl","w_genapp_about",PBORCA_WINDOW,$buf);
my $buf2=$buf;
ok(!$rc);
$buf2=~s/\r\n/:/g;
ok($buf2 =~ /^forward:global type/);

#################################################
# Import
#################################################
my $errbuf;
my $buf3=$buf;
$buf3=~s/commandbutton/commandbuttonxx/;
$rc=$ses->Import($cwd."orca_test2.pbl","w_genapp_about_test",PBORCA_WINDOW,"Imported by Perl",$buf3,\$errbuf);
ok($rc==-11 && $errbuf=~/Illegal data type: commandbuttonxx/);

$ses->Del($cwd."orca_test2.pbl","w_genapp_about_test",PBORCA_WINDOW);

$buf=~s/w_genapp_about/w_genapp_about_test2/g;
$rc=$ses->Import($cwd."orca_test2.pbl","w_genapp_about_test2",PBORCA_WINDOW,"Imported by Perl",$buf,\$errbuf);
ok($rc==0 && $errbuf eq '');

#################################################
# ImportList
#################################################
my ($w1,$w2);
$rc=$ses->Export("orca_test2.pbl","w_genapp_about",PBORCA_WINDOW,$w1);
ok(!$rc);
$rc=$ses->Export("orca_test2.pbl","w_genapp_toolbars",PBORCA_WINDOW,$w2);
ok(!$rc);
$rc=$ses->ImportList(\$errbuf,
        {
            Library=>$cwd."orca_test2.pbl",
            Name=>'w_genapp_about',
            Type=>PBORCA_WINDOW,
            Comment=>'comment 1',
            Syntax=>$w1
        },
        {
            Library=>$cwd."orca_test2.pbl",
            Name=>'w_genapp_toolbars',
            Type=>PBORCA_WINDOW,
            Comment=>'comment 2',
            Syntax=>$w2
        },
        );
ok(!$rc && $errbuf eq '');

#################################################
# Regenerate
#################################################
$rc=$ses->Regenerate($cwd."orca_test2.pbl","w_genapp_frame",PBORCA_WINDOW,\$errbuf);
ok(!$rc && $errbuf eq "");

#################################################
# ApplicationRebuild
#################################################
if ( $ver >= 7 ) {
	$rc=$ses->ApplicationRebuild(PBORCA_FULL_REBUILD,\$errbuf);
	ok(!$rc && $errbuf eq "");
} else {
	ok(1);
}

#################################################
# LibCreate
#################################################
unlink "test.pbl";
$rc=$ses->LibCreate("test.pbl","test library");
ok(!$rc);

#################################################
# LibInfo
#################################################
my ($comment,$n);
$rc=$ses->LibInfo("test.pbl",\$comment,\$n);
ok(!$rc && $comment eq "test library" && $n==0);

#################################################
# Copy
#################################################
$rc=$ses->Copy("orca_test.pbl","test.pbl","orca_test",PBORCA_APPLICATION);
ok(!$rc);
$rc=$ses->Copy("orca_test2.pbl","test.pbl","w_genapp_about",PBORCA_WINDOW);
ok(!$rc);

$rc=$ses->Move("orca_test2.pbl","test.pbl","w_genapp_about_test2",PBORCA_WINDOW);
ok(!$rc);

#################################################
# Move
#################################################
$rc=$ses->Move("orca_test2.pbl","test.pbl","xxx",PBORCA_WINDOW);
ok($rc==-3);

#################################################
# LibDirList
#################################################
my @names=$ses->LibDirList('test.pbl');
ok(join(":",sort @names) eq "orca_test:w_genapp_about:w_genapp_about_test2");

#################################################
# LibDir
#################################################
my @objects;
$rc=$ses->LibDir("test.pbl",\@objects);
ok(join(":",map($_->{Type}."/".$_->{Name},@objects)) eq "0/orca_test:7/w_genapp_about:7/w_genapp_about_test2");

#################################################
# LibCommentModify
#################################################
$rc=$ses->LibCommentModify("test.pbl","new comment");
$ses->LibInfo("test.pbl",\$comment,\$n);
ok(!$rc && $comment eq "new comment" && $n==3);

#################################################
# LibDel
#################################################
$rc=$ses->LibDel("test.pbl");
ok(!$rc && ! -f "test.pbl");

if ( $ver < 9 ) {
    #################################################
    # CheckOut
    #################################################
	unlink("a.pbl");
    $rc=$ses->LibCreate("a.pbl","work library");
    ok(!$rc);

	$rc=$ses->CheckOut("w_genapp_about",PBORCA_WINDOW,"orca_test2.pbl","a.pbl","Ilya",1);
    ok(!$rc);

    $rc=$ses->CheckOut("w_genapp_about",PBORCA_WINDOW,"orca_test2.pbl","a.pbl","Ilya",1);
    ok($rc==-18);

    #################################################
    # ListCheckOutEntries
    #################################################
    my @storage;
    $rc=$ses->ListCheckOutEntries("orca_test2.pbl",\@storage);
    ok(!$rc && join(":",map($_->{Mode}."/".$_->{LibName}."/".$_->{UserID}."/".$_->{Name},@storage)) eq "d/a.pbl/Ilya/w_genapp_about");

    #################################################
    # CheckIn
    #################################################
    $rc=$ses->CheckIn("w_genapp_about",PBORCA_WINDOW,"orca_test2.pbl","a.pbl","Ilya",1);
    ok(!$rc);
} else {
	ok(1);
	ok(1);
	ok(1);
	ok(1);
	ok(1);
}

#################################################
# DllCreate
#################################################
unlink 'orca_test2.pbd';
$rc=$ses->DllCreate($cwd.'orca_test2.pbl',undef,PBORCA_P_CODE);
ok(!$rc);

#################################################
# ExeCreate
#################################################
unlink 'orca_test.exe';
if ( $ver >= 9 ) {
	$rc=$ses->SetExeInfo({
		CompanyName => 'CompanyName',       #
		ProductName => 'ProductName',       #
		Description => 'Description',		#
		Copyright => 'Copyright',           #
		FileVersion => '9,9,9,9',           #
		FileVersionNum => '8,8,8,8',		#not used?
		ProductVersion => 'ProductVersion', #
		ProductVersionNum => '7,7,7,7',		#not used?
	}
	);
	ok(!$rc);
} else {
	ok(1);
}
$rc=$ses->ExeCreate($cwd.'orca_test.exe',
    undef,
    undef,
    [0,1],
    PBORCA_P_CODE,
    \$errbuf);
ok(!$rc && $errbuf=='');

#################################################
# ObjectQueryReference
#################################################
my @storage;
$rc=$ses->ObjectQueryReference($cwd.'orca_test.pbl',"orca_test",PBORCA_APPLICATION,\@storage);
ok(@storage==1 && $storage[0]{Name} eq "w_genapp_frame" && $storage[0]{RefType} eq 'o');

#################################################
# ObjectQueryHierarchy
#################################################
my @storage;
$rc=$ses->ObjectQueryHierarchy($cwd.'orca_test2.pbl',"w_genapp_about_child",PBORCA_WINDOW,\@storage);
ok(!$rc && @storage==1 && $storage[0] eq "w_genapp_about");

#print "$errbuf\n";
#print $rc.":".$ses->GetError()."\n";

$ses->Close();
ok(1);

