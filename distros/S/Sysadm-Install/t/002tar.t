#####################################
# Tests for Sysadm::Install/s untar()
#####################################

use Test::More;

use Sysadm::Install qw(:all);
use File::Spec;
use File::Path;
use Carp;
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

BEGIN {
    eval {
        require Archive::Tar;
    };

    if ($@) {
        plan skip_all => "Skipping Archive::Tar tests (not installed)";
    } else {
        plan tests => 9;
    }
}

my $TEST_DIR = ".";
$TEST_DIR = "t" if -d 't';

#####################################################################
# Test unzipped tar
#####################################################################
my $tarfile = File::Spec->catfile($TEST_DIR, "canned", "test.tar");

untar($tarfile);

ok(-d "test", "Untarred directory 'test' exists");

is(readfile("test/a"), "file-a\n", "Testing file a in tar archive");
is(readfile("test/b"), "file-b\n", "Testing file b in tar archive");

##############
sub readfile {
##############
    open FILE, "<$_[0]" or croak "Cannot open $_[0] ($!)";
    my $data = join '', <FILE>;
    close FILE;
    return $data;
}

rmtree "test";

#####################################################################
# Test zipped tar
#####################################################################
$tarfile = File::Spec->catfile($TEST_DIR, "canned", "test.tar");

untar($tarfile);

ok(-d "test", "Untarred directory 'test' exists");

is(readfile("test/a"), "file-a\n", "Testing file a in tar archive");
is(readfile("test/b"), "file-b\n", "Testing file b in tar archive");

rmtree "test";

#####################################################################
# Test zipped tar with different top dir
#####################################################################
$tarfile = File::Spec->catfile($TEST_DIR, "canned", "testa.tar");

untar($tarfile);

ok(-d "testa", "Untarred directory 'testa' exists");

is(readfile("testa/a"), "file-a\n", "Testing file a in tar archive");
is(readfile("testa/b"), "file-b\n", "Testing file b in tar archive");

rmtree "testa";
