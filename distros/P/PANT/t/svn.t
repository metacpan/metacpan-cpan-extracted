use Test::More tests => 12;
use Config;

BEGIN { use_ok('PANT') };
BEGIN { use_ok('PANT::Svn') };

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
Updated to revision 11.
EOF
    push(@delfiles, "xxxtest.txt");

my $svn = Svn();
ok($svn, "Svn allocated");
my $command = qq{$this_perl -ne "{ print; }" xxxtest.txt};
ok($svn->Run($command), "Svn Run $command ok 1");
ok($svn->HasUpdate(), "An updated file has been spotted");
ok(!$svn->HasConflict(), "A file has not conflicted");
WriteFile("xxxtest.txt", <<'EOF');
M something.cpp
EOF
ok($svn->Run(qq{$this_perl -ne "{ print; }" xxxtest.txt}), "Svn Run ok 2");
ok($svn->HasUpdate(), "An update has occured");
ok(!$svn->HasConflict(), "A file has not conflicted");
WriteFile("xxxtest.txt", <<'EOF');
C something.cpp
EOF

ok($svn->Run(qq{$this_perl -ne "{ print; }" xxxtest.txt}), "Svn Run ok 3");
ok(!$svn->HasUpdate(), "An update has not occured");
ok($svn->HasConflict(), "A file has conflicted");
undef $svn; # remove file reference
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
