# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 33;

BEGIN { use_ok('PANT') };

#########################

my $outfile = "xxxtest.html";
my @testarg = ("-output", $outfile);
@ARGV = @testarg;

my $titlename = "This is my title";
StartPant($titlename);
EndPant();
ok(-f $outfile, "HTML output generated from @testarg");
my $fcontents = FileLoad($outfile);

like($fcontents, qr{<title\s*>$titlename</title\s*>}i, "Title is as expected");

ok(unlink($outfile), "Remove file works");

@ARGV =@testarg;
StartPant();

ok(Task(1, "Task works"), "Task works using @testarg");
ok(Task(1, "2nd Task Works"), "2nd task works");
ok(Command("echo hello"), "Command echo works");

my @dellist = ();
my $now = time;
$now --;
ok(open(TFILE, ">test.tmp"), "Created temporary file");
push(@dellist, "test.tmp");
print TFILE "This is a test file hello world\n";
close(TFILE);
ok(utime($now, $now, "test.tmp"), "Set time stamp back a sec");

ok(open(TFILE, ">test2.tmp"), "Created 2nd temporary file");
print TFILE "This is another test file hello world\n";
close(TFILE);
push(@dellist, "test2.tmp");

ok(!NewerThan(sources=>[qw(test.tmp)], targets=>[qw(test2.tmp)]), "Newer test");
ok(NewerThan(sources=>[qw(test2.tmp)], targets=>[qw(test.tmp)]), "Older test");

ok(CopyFile("test5.tmp", "test6.tmp") == 0, "Copied non existant file failed");
ok(CopyFile("test2.tmp", "test3.tmp"), "Copied file");
ok(MoveFile("test3.tmp", "test4.tmp"), "Moved file");
ok(! -f "test3.tmp", "test3.tmp has gone");
ok(-f "test4.tmp", "test4.tmp exists");
is(-s "test4.tmp", -s "test2.tmp", "Files are the same size");

ok(FileCompare("test2.tmp", "test4.tmp"), "Files are the same contents");

push(@dellist, "test4.tmp");

ok(unlink(@dellist), "Removed temporary files");


ok(MakeTree("testdir/mytest"), "Made a new directory");
ok(-d "testdir", "Testdir exists");
ok(-d "testdir/mytest", "mytest subdirectory exists");
ok(CopyTree("testdir", "newtestdir"), "Copy tree suceeded");
ok(-d "newtestdir", "New directory exists");
ok(-d "newtestdir/mytest", "New directory exists");
ok(RmTree("testdir"), "Removed testdir");
ok(! -d "testdir", "testdir has been removed");
ok(RmTree("newtestdir"), "Removed testdir");
ok(! -d "newtestdir", "newtestdir has been removed");



EndPant();



$fcontents = FileLoad($outfile);
like($fcontents, qr{<li\s*>\s*Task works}i, "Task1 appears in output");
like($fcontents, qr{<li\s*>\s*2nd Task works}i, "Task2 appears in output");
ok(unlink($outfile), "Remove file works");


sub FileLoad {
    my $fname = shift;
    local(*INPUT, $/);
    open (INPUT, $fname) || die "Can't open file $fname: $!";
    return <INPUT>;
}
