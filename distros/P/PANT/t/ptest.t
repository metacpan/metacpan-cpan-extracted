use Test::More tests => 9;
BEGIN { use_ok('PANT') };
BEGIN { use_ok('PANT::Test') };

my $outfile = "xxxtest2.html";
my @testarg = ("-output", $outfile);
@ARGV = @testarg;
@delfiles = ();
StartPant();
push(@delfiles, $outfile);
ok(RunTests(tests=>[qw(t/fake/fake.t t/fake/fake2.t)], directory=>"."), "Run tests completes ok");

EndPant();

my $contents = FileLoad($outfile);
like($contents, qr{Summary: Test Files 2}i, "Test summary appears");
like($contents, qr{Summary: Total Tests 20}i, "Test summary appears");
like($contents, qr{Took\s+\d+\s+wallclock}i, "Benchmark appears");
like($contents, qr{td[^>]+id="fail"}i, "Failure tag detected");
like($contents, qr{td[^>]+id="pass"}i, "Pass tag detected");
like($contents, qr{Looks like you failed}i, "Stderr junk detected");
unlink(@delfiles) unless $ENV{DEBUGTEST};

sub FileLoad {
    my $fname = shift;
    local(*INPUT, $/);
    open (INPUT, $fname) || die "Can't open file $fname: $!";
    return <INPUT>;
}
