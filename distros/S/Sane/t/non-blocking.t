# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl non-blocking.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 14;
BEGIN { use_ok('Sane') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

SKIP: {
    skip "libsane 1.0.19 or better required", 13
     unless Sane->get_version_scalar > 1.000018;

my $test = Sane::Device->open('test');
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'opening test backend');

$options = $test->get_option_descriptor(10);
is ($options->{name}, 'test-picture', 'test-picture');

my $info = $test->set_option(10, 'Color pattern');
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'Color pattern');

$info = $test->set_option(19, SANE_TRUE);
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'non-blocking');

$info = $test->set_option(20, SANE_TRUE);
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'fd option');

$test->start;
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'start');

$test->set_io_mode (SANE_TRUE);
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'non-blocking');

my $fd = $test->get_select_fd;
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'fd option');

my $param = $test->get_parameters;
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'get_parameters');

if ($param->{lines} >= 0) {
 my $filename = 'fd.pnm';
 open my $fh, '>', $filename;
 binmode $fh;

 my ($data, $len);
 my $rin = '';
 my $rout = '';
 vec($rin, $fd, 1) = 1;
 my $i = 1;
 do {
  select($rout=$rin,undef,undef,undef);
  ($data, $len) = $test->read ($param->{bytes_per_line});
  print $fh substr($data, 0, $len) if ($data);
 }
 while ($Sane::STATUS == SANE_STATUS_GOOD);
 cmp_ok($Sane::STATUS, '==', SANE_STATUS_EOF, 'EOF');
 is ($data, undef, 'EOF data');
 is ($len, 0, 'EOF len');

 $test->cancel;
 close $fh;
 is (-s $filename, $param->{bytes_per_line}*$param->{lines}, 'image size');
}
};
