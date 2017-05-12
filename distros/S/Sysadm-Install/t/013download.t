#####################################
# Tests for Sysadm::Install
#####################################

use Test::More tests => 2;
use Sysadm::Install qw(:all);
use File::Temp qw(tempdir);

eval {
   download "file:///very/unlikely/that/this/file/exists";
};

ok $@, "download of non-existent file";

my $var = "SI_ALL_TESTS";

SKIP: {
    if(! exists $ENV{ $var }) {
        skip "only with $var set", 1;
    }

    $ENV{use_proxy} = 1;

    my ($dir) = tempdir( CLEANUP => 1 );
    cd $dir;
    download "http://perlmeister.com/index.html";
    ok(-s "index.html", "download ok");
    cdback;
};
