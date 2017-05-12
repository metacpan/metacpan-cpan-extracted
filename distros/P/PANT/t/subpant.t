# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use File::Spec::Functions qw(:ALL);
use Test::More tests => 27;
use Cwd;

BEGIN { use_ok('PANT') };

#########################

my $outfile = "./xxxtest.html";
my @testarg = ("-output", $outfile);
@ARGV = @testarg;

my @dellist = ($outfile);

StartPant("Test UpdateFile stuff");


WriteFile("subpant1.pl", <<'EOF');
#! perl -w
use PANT;

StartPant("Subpant test");
Phase(1);

EndPant();
EOF
push(@dellist, "subpant1.pl");
ok(CallPant("subpant1.pl"), "Sub pant called");
EndPant();
my $contents = FileLoad($outfile);
ok($contents, "Contents of $outfile read");
like($contents, qr/href=\"[^\"]+\"/i, "Found the reference to the sub html"); #"
my($href) = $contents =~ /href=\"([^\"]+)\"/i; #"
ok(-f $href, "Sub pant file $href exists");
push(@dellist, $href);
my($v1,$d1, $f1) = splitpath(rel2abs($outfile));
my($v2,$d2, $f2) = splitpath(rel2abs($href));
cmp_ok($v1, 'eq', $v2, "Volumes $v1 + $v2 are the same");
cmp_ok($d1, 'eq', $d2, "Directories $d1 + $d2 are the same");
ok(unlink(@dellist), "Clean up old files");
@dellist = ();

WriteFile("t/subpant2.pl", <<'EOF');
#! perl -w
BEGIN { unshift(@INC, ".."); }
use PANT;

StartPant("Subpant test");
Phase(1);

EndPant();
EOF
push(@dellist, "t/subpant2.pl");

@ARGV = @testarg;


StartPant("Subpant 2 test");
push(@dellist, $outfile);
ok(CallPant("subpant2.pl", directory=>"t"), "Subpant called ok");
EndPant();

$contents = FileLoad($outfile);
ok($contents, "Contents of $outfile read");
like($contents, qr/href=\"[^\"]+\"/i, "Found the reference to the sub html"); #"
($href) = $contents =~ /href=\"([^\"]+)\"/i;  #"
push(@dellist, $href);
ok(-f $href, "Sub pant file $href exists");
($v1,$d1, $f1) = splitpath(rel2abs($outfile));
($v2,$d2, $f2) = splitpath(rel2abs($href));
cmp_ok($v1, 'eq', $v2, "Volumes $v1 + $v2 are the same");
cmp_ok($d1, 'eq', $d2, "Directories $d1 + $d2 are different");
ok(unlink(@dellist), "Clean up old files @dellist");
@dellist = ();

WriteFile("t/subpant3.pl", <<'EOF');
#! perl -w
BEGIN { unshift(@INC, ".."); }
use PANT;

StartPant("Subpant test");
Phase(1);

EndPant();
EOF
push(@dellist, "t/subpant3.pl");

@ARGV = @testarg;
StartPant("Subpant 3 test");
push(@dellist, $outfile);
my $testdir = catfile(getcwd(), "t");
ok(CallPant("subpant3.pl", directory=>$testdir, logname=>"newlog"), "Subpant called ok");
EndPant();
$contents = FileLoad($outfile);
ok($contents, "Contents of $outfile read");
like($contents, qr/href=\"[^\"]+\"/i, "Found the reference to the sub html"); #"
($href) = $contents =~ /href=\"([^\"]+)\"/i;  #"
like($href, qr/newlog/, "Logfile $href contains newlog");
push(@dellist, $href);
ok(unlink(@dellist), "Clean up old files @dellist");
@dellist = ();

WriteFile("t/subpant4.pl", <<'EOF');
#! perl -w
BEGIN { unshift(@INC, ".."); }
use PANT;

StartPant("Subpant test");
Phase(1);

EndPant();
EOF
push(@dellist, "t/subpant4.pl");

ok(mkdir("tempdir"), "Create temp log dir");
$outfile = rel2abs("tempdir/build1.html");
@ARGV = ("-output", $outfile);
push(@dellist, $outfile);


StartPant("Subpant 4 test");
$testdir = catfile(getcwd(), "t");
ok(CallPant("subpant4.pl", directory=>$testdir, logname=>"newlog"), "Subpant called ok");
EndPant();
$contents = FileLoad($outfile);
ok($contents, "Contents of $outfile read");
like($contents, qr/href=\"[^\"]+\"/i, "Found the reference to the sub html"); #"
($href) = $contents =~ /href=\"([^\"]+)\"/i;  #"
like($href, qr/newlog/, "Logfile $href contains newlog");
push(@dellist, "tempdir/$href");

ok(unlink(@dellist), "Clean up old files @dellist");
@dellist = ();
ok(rmdir("tempdir"), "Removed the temp directory");

sub WriteFile {
	my($name, $contents) = @_;
	open(FILE, ">$name") || die "Can't write file $name: $!";
	print FILE $contents;
	close(FILE);
}


sub FileLoad {
    my $fname = shift;
    local(*INPUT, $/);
    open (INPUT, $fname) || die "Can't open file $fname: $!";
    return <INPUT>;
}

