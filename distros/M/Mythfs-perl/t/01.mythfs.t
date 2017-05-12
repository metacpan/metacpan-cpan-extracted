#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempdir);
use FindBin '$Bin';
use constant TEST_COUNT => 1;

use lib "$Bin/lib","$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";
use Test::More tests => 18;

my $test_xml = "gunzip -c $Bin/data/dummy_xml.gz|";
my $mount    = tempdir(CLEANUP=>1);
my $script   = "$Bin/../blib/script/mythfs.pl";

my $result = system 'perl','-I',"$Bin/../blib/lib",$script,"--XML=$test_xml",'dummy_host',$mount;
is($result,0,'mount script ran ok');
wait_for_mount($mount,20);
ok(-d  $mount,              "mountpoint exists");

ok(-e "$mount/Hamlet.mpg",  "expected file exists");
ok(-d "$mount/The Simpsons","expected directory exists");
ok(-e "$mount/The Simpsons/Pulpit Friction.mpg","expected subfile exists");
is(-s "$mount/The Simpsons/Pulpit Friction.mpg",3295787392,"file has correct size");
my @stat = stat("$mount/The Simpsons/Pulpit Friction.mpg");
is($stat[9],1367196599,'file has correct mtime');

ok(opendir(my $dir,$mount),"can open mounted directory");
my @mpgs = grep /\.mpg$/,readdir($dir);
is(scalar @mpgs,53,'expected number of recordings at top level');
rewinddir($dir);
my @dirs = grep {-d "$mount/$_"} readdir($dir);
is(scalar @dirs,19,'expected number of directoreis at top level');
ok(closedir($dir),"can close mounted directory");

ok(opendir($dir,"$mount/The Simpsons"),"can open subdirectory");
@mpgs = grep /\.mpg$/,readdir($dir);
is(scalar @mpgs,26,'expected number of recordings in subdirectory');
ok(closedir($dir),"can close subdirectory");

$result    = system 'fusermount','-u',$mount;
is($result,0,'fusermount ran ok');

# mount with special pattern
$result = system $script,"--XML=$test_xml",'-p=%C/%T:%S','--trim=:','dummy_host',$mount;
is($result,0,'mount script ran ok');
wait_for_mount($mount,20);

ok(-e "$mount/Fantasy/Penelope.mpg",'pattern interpolation and trimming worked correctly');

$result    = system 'fusermount','-u',$mount;
is($result,0,'fusermount ran ok');


exit 0;

sub wait_for_mount {
    my ($mtpt,$timeout) = @_;
    my $marker_file     = '.fuse-mythfs';
    my $path            = "$mtpt/$marker_file";
    local $SIG{ALRM} = sub {die "timeout"};
    alarm($timeout);
    eval {
	while (1) {
	    sleep 1;
	    last if -e $path;
	}
	alarm(0);
    };
    return 1 unless $@;
}
