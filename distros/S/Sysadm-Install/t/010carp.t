#####################################
# Tests for Sysadm::Install
#####################################

use Test::More tests => 3;

use Sysadm::Install qw(:all);
use File::Spec;
use File::Path;
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

my $TEST_DIR = ".";
$TEST_DIR = "t" if -d 't';

#################################
# cd
#################################
eval {
    cd "/this/directory/does/not/exist";
};

if($@) {
    like($@, qr(010carp.t), "'cd' reports failure in calling script");
} else {
    ok(0, "cd succeeded, but should have failed");
}

#################################
# mkd
#################################
eval {
    mkd "///";
};

if($@) {
    like($@, qr(010carp.t), "'mkd' reports failure in calling script");
} else {
    ok(0, "mkd succeeded, but should have failed");
}

#################################
# cp
#################################
eval {
    cp "Ill/go/crazy/if/this/whacko/directory/actually/exists", "//x";
};

if($@) {
    like($@, qr(010carp.t), "'cp' reports failure in calling script");
} else {
    ok(0, "cp succeeded, but should have failed");
}
