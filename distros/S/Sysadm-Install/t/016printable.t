#####################################
# Tests for Sysadm::Install/s utf8 handling
#####################################
use Test::More;

use Sysadm::Install qw(:all);
use File::Spec;
use File::Path;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

plan tests => 1;

is(printable('-'), '-', 'printable: -');
