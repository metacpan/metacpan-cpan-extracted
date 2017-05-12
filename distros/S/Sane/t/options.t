# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl options.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { use_ok('Sane') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

plan skip_all => 'libsane 1.0.19 or better required'
     unless Sane->get_version_scalar > 1.000018;

my @array = Sane->get_version;
is ($#array, 2, 'get_version');

@array = Sane->get_devices;
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'get_devices');

my $test = Sane::Device->open('test');
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'open');

my $n = $test->get_option(0);
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'get number of options');

my $options = $test->get_option_descriptor(21);
if ($options->{name} eq 'enable-test-options') {
 $info = $test->set_option(21, SANE_TRUE);
 cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'enable-test-options');

 for (my $i = 0; $i < $n; $i++) {
  my $options = $test->get_option_descriptor($i);
  isnt ($options, undef, 'get_option_descriptor');

  if ($options->{cap} & SANE_CAP_SOFT_SELECT) {
   my $in;
   if ($options->{constraint_type} == SANE_CONSTRAINT_RANGE) {
    if ($options->{max_values} == 1) {
     $in = $options->{constraint}{min};
    }
    else {
     for (my $i = 0; $i < $options->{max_values}; $i++) {
      $in->[$i] = $options->{constraint}{min};
     }
    }
   }
   elsif ($options->{constraint_type} == SANE_CONSTRAINT_STRING_LIST or
                     $options->{constraint_type} == SANE_CONSTRAINT_WORD_LIST) {
    if ($options->{max_values} == 1) {
     $in = $options->{constraint}[0];
    }
    else {
     for (my $i = 0; $i < $options->{max_values}; $i++) {
      $in->[$i] = $options->{constraint}[0];
     }
    }
   }
   elsif ($options->{type} == SANE_TYPE_BOOL or
                                         $options->{type} == SANE_TYPE_BUTTON) {
    $in = SANE_TRUE;
   }
   elsif ($options->{type} == SANE_TYPE_STRING) {
    $in = 'this is a string with no constraint';
   }
   elsif ($options->{type} == SANE_TYPE_INT) {
    if ($options->{max_values} == 1) {
     $in = 12345678;
    }
    else {
     for (my $i = 0; $i < $options->{max_values}; $i++) {
      $in->[$i] = 12345678;
     }
    }
   }
   elsif ($options->{type} == SANE_TYPE_FIXED) {
    if ($options->{max_values} == 1) {
     $in = 1234.5678;
    }
    else {
     for (my $i = 0; $i < $options->{max_values}; $i++) {
      $in->[$i] = 1234.5678;
     }
    }
   }
   if (defined $in) {
    SKIP: {
     skip 'Pressing buttons produces too much output', 1 if $options->{type} == SANE_TYPE_BUTTON;

     $info = $test->set_option($i, $in);
    };
    if ($options->{cap} & SANE_CAP_INACTIVE) {
     cmp_ok($Sane::STATUS, '==', SANE_STATUS_INVAL, 'set_option');
    }
    else {
     cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'set_option');
    }

    if ($options->{type} != SANE_TYPE_BUTTON) {
     $out = $test->get_option($i);
     if ($options->{cap} & SANE_CAP_INACTIVE) {
      cmp_ok($Sane::STATUS, '==', SANE_STATUS_INVAL, 'get_option');
     }
     elsif ($info & SANE_INFO_INEXACT) {
      cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'get_option');
     }
     elsif ($options->{type} == SANE_TYPE_FIXED) {
      if ($in == 0) {
       is (abs($out) < 1.e-6, 1, 'get_option');
      }
      else {
       is (abs($out-$in)/$in < 1.e-6, 1, 'get_option');
      }
     }
     else {
      is_deeply ($out, $in, 'get_option');
     }
    }
   }
  }
  if ($options->{cap} & SANE_CAP_AUTOMATIC and not $options->{cap} & SANE_CAP_INACTIVE) {
   $info = $test->set_auto($i);
   cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'set_auto');
  }
 }
}

done_testing();
