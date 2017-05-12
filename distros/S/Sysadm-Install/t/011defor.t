#####################################
# Tests for Sysadm::Install
#####################################

use Test::More tests => 5;

use Sysadm::Install qw(:all);

my $undef;
my $defined = 5;

ok(!defined $undef, "undef value undefined");
ok(defined $defined, "defined value defined");

def_or($undef, 42);
is($undef, 42, "new value assigned");

def_or($defined, 42);
is($defined, 5, "no new value assigned");

$defined = 0;
def_or($defined, 42);
is($defined, 0, "no new value assigned");
