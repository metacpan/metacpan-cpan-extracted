use Test::More tests => 15;
use Config;

BEGIN { use_ok('PANT') };
BEGIN { use_ok('PANT::Cvs') };

my $outfile = "xxxtest3.html";
my @testarg = ("-output", $outfile);

$this_perl = $^X; 
if ($^O ne 'VMS') {
    $this_perl .= $Config{_exe}
    unless $this_perl =~ m/$Config{_exe}$/i;
}

@ARGV = @testarg;
@delfiles = ($outfile);
StartPant();

WriteFile("xxxtest.txt", <<'EOF');
U something.cpp
U something.h
U foo.cpp
P foo.h
P ReadMe.txt
P resource.h
P thing.rc
cvs update: Updating hlp
cvs update: Updating html
cvs update: Updating res
EOF
    push(@delfiles, "xxxtest.txt");

my $cvs = Cvs();
ok($cvs, "Cvs allocated");
my $command = qq{$this_perl -ne "{ print; }" xxxtest.txt};
ok($cvs->Run($command), "Cvs Run $command ok");
ok($cvs->HasUpdate(), "An updated file has been spotted");
ok(!$cvs->HasLocalMod(), "A local file has not been modifed");
ok(!$cvs->HasConflict(), "A file has not conflicted");
WriteFile("xxxtest.txt", <<'EOF');
M something.cpp
? weird.xx
cvs update: Updating hlp
cvs update: Updating html
cvs update: Updating res
EOF
ok($cvs->Run(qq{$this_perl -ne "{ print; }" xxxtest.txt}), "Cvs Run ok");
ok(!$cvs->HasUpdate(), "An update has not occured");
ok($cvs->HasLocalMod(), "A local file has  been modifed");
ok(!$cvs->HasConflict(), "A file has not conflicted");
WriteFile("xxxtest.txt", <<'EOF');
C something.cpp
? weird.xx
cvs update: Updating hlp
cvs update: Updating html
cvs update: Updating res
EOF

ok($cvs->Run(qq{$this_perl -ne "{ print; }" xxxtest.txt}), "Cvs Run ok");
ok(!$cvs->HasUpdate(), "An update has not occured");
ok(!$cvs->HasLocalMod(), "A local file has  been modifed");
ok($cvs->HasConflict(), "A file has conflicted");
undef $cvs; # remove file reference
EndPant();

unlink(@delfiles);

sub FileLoad {
    my $fname = shift;
    local(*INPUT, $/);
    open (INPUT, $fname) || die "Can't open file $fname: $!";
    return <INPUT>;
}

sub WriteFile {
	my($name, $contents) = @_;
	open(FILE, ">$name") || die "Can't write file $name: $!";
	print FILE $contents;
	close(FILE);
}
