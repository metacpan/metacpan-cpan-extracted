# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl data.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { use_ok('Sane') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

plan skip_all => 'libsane 1.0.19 or better required'
     unless Sane->get_version_scalar > 1.000018;

my $test = Sane::Device->open('test');
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'opening test backend');

$options = $test->get_option_descriptor(10);
is ($options->{name}, 'test-picture', 'test-picture');

my $info = $test->set_option(10, 'Color pattern');
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'Color pattern');

my $n = $test->get_option(0);
my $read_length_zero;
if ($n > 52) {
  $options = $test->get_option_descriptor(52);
  if ($options->{name} eq 'read-length-zero') {
    $read_length_zero = 1;
    $info = $test->set_option(52, SANE_TRUE);
    cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'read-length-zero');
  }
}

$options = $test->get_option_descriptor(2);
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'Modes');

for my $mode (@{$options->{constraint}}) {
 my $info = $test->set_option(2, $mode);
 cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, $mode);

 $test->start;
 cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'start');

 my $param = $test->get_parameters;
 cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'get_parameters');

 if ($param->{lines} >= 0) {
  my $filename = "$mode.pnm";
  open my $fh, '>', $filename;
  binmode $fh;

  $test->write_pnm_header($fh, $param->{format}, $param->{pixels_per_line},
                                           $param->{lines}, $param->{depth});

  my ($data, $len);
  do {
   ($data, $len) = $test->read ($param->{bytes_per_line});
   is (length($data), 0, 'length-zero')
     if ($read_length_zero and $len == 0 and $Sane::STATUS == SANE_STATUS_GOOD);
   print $fh substr($data, 0, $len) if ($data);
  }
  while ($Sane::STATUS == SANE_STATUS_GOOD);
  cmp_ok($Sane::STATUS, '==', SANE_STATUS_EOF, 'EOF');
  is ($data, undef, 'EOF data');
  is ($len, 0, 'EOF len');

  $test->cancel;
  close $fh;
 }
}

done_testing();
