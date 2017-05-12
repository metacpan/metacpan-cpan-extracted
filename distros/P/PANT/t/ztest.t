use Test::More tests => 14;
BEGIN { use_ok('PANT') };
BEGIN { use_ok('PANT::Zip') };

my $outfile = "xxxtest3.html";
my @testarg = ("-output", $outfile);
my $zipname = "foo.zip";
@ARGV = @testarg;
@delfiles = ();
StartPant();
push(@delfiles, $outfile);
{
    my $zip = Zip($zipname);
    ok($zip, "Zip object created");
    ok($zip->AddFile("ChangeLog", "Changes"), "Add Changes");
    ok($zip->AddTree('t', 'tests', sub { -f }), "Add tree t as tests");
    ok($zip->Close(), "ZIP written");
    ok(-f $zipname, "Zip file now exists");
    push(@delfiles, $zipname);
}
EndPant();

my $contents = FileLoad($outfile);
ok($contents, "File $outfile read");
like($contents, qr{title}i, "Test summary appears");

{
    require Archive::Zip;
    $zip = Archive::Zip->new("foo.zip");
    ok($zip, "Zip file read");
    ok($zip->memberNamed( 'Changes' ), "Changes found");
    ok(!$zip->memberNamed( 'ChangeLog' ), "ChangeLog not found");
    ok($zip->memberNamed( 'tests/basic.t' ), "tests/basic.t found");
    ok(!$zip->memberNamed( 't/basic.t' ), "t/basic.t not found");
}

unlink(@delfiles);

sub FileLoad {
    my $fname = shift;
    local(*INPUT, $/);
    open (INPUT, $fname) || die "Can't open file $fname: $!";
    return <INPUT>;
}
