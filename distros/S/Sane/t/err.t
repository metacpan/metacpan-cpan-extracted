# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl err.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 38;
BEGIN { use_ok('Sane') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

SKIP: {
    skip "libsane 1.0.19 or better required", 37 unless
     Sane->get_version_scalar > 1.000018;

my $test = Sane::Device->open('test');
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'opening test backend');

my $options = $test->get_option_descriptor(21);
is ($options->{name}, 'enable-test-options', 'enable-test-options');

my $info = $test->set_option(21, SANE_TRUE);
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'set enable-test-options');

$options = $test->get_option_descriptor(16);
is ($options->{name}, 'read-return-value', 'read-return-value');

my %status = (
 'SANE_STATUS_UNSUPPORTED' => SANE_STATUS_UNSUPPORTED,
 'SANE_STATUS_CANCELLED' => SANE_STATUS_CANCELLED,
 'SANE_STATUS_DEVICE_BUSY' => SANE_STATUS_DEVICE_BUSY,
 'SANE_STATUS_INVAL' => SANE_STATUS_INVAL,
 'SANE_STATUS_EOF' => SANE_STATUS_EOF,
 'SANE_STATUS_JAMMED' => SANE_STATUS_JAMMED,
 'SANE_STATUS_NO_DOCS' => SANE_STATUS_NO_DOCS,
 'SANE_STATUS_COVER_OPEN' => SANE_STATUS_COVER_OPEN,
 'SANE_STATUS_IO_ERROR' => SANE_STATUS_IO_ERROR,
 'SANE_STATUS_NO_MEM' => SANE_STATUS_NO_MEM,
 'SANE_STATUS_ACCESS_DENIED' => SANE_STATUS_ACCESS_DENIED,
);

for (keys %status) {
 my $info = $test->set_option(16, $_);
 cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, "set $_");

 $test->start;
 cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'start');

 my ($data, $len) = $test->read (100);
 cmp_ok($Sane::STATUS, '==', $status{$_}, $_);
 $test->cancel;
}
};
