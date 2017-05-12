#####################################
# Tests for Sysadm::Install/s utf8 handling
#####################################
use Test::More;

use Sysadm::Install qw(:all);
use File::Spec;
use File::Path;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

BEGIN {
    eval {
        require 5.8.0;
        use Encode qw(is_utf8);
        use utf8; # local scope only, needs to be repeated below
    };

    if ($@) {
        plan skip_all => "Skipping utf8 tests (requires perl >5.8)";
    } else {
        plan tests => 2;
    }
}

my $TEST_DIR = ".";
$TEST_DIR = "t" if -d 't';

my $utf8file = File::Spec->catfile($TEST_DIR, "canned", "utf8.txt");

my $data = slurp $utf8file, {utf8 => 1};
ok is_utf8( $data ), "slurped utf8 file data stored in utf8";

use utf8;
like $data, qr/äÜß/, "slurped utf8 file data";
