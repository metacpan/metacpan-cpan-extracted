# -*- Mode: Perl -*-
# t/02_basic.t : test basic methods

use vars qw($TEST_DIR);
$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# change 'tests => 1' to 'tests => last_test_to_print';
use Test;
BEGIN {
  # preload module
  use Speech::Rsynth;
  plan tests => 4*scalar(@Speech::Rsynth::ACCESSORS);
}

# load common subs
do "$TEST_DIR/common.plt";
@axs = @Speech::Rsynth::ACCESSORS;

# new object
$rs = Speech::Rsynth->new();

# 1..n : get-access
foreach (@axs) {
  eval { $get{$_} = $rs->$_(); };
  isok("$_() [get]", !$@);
}

# n+1..2n : configure read access
%cfg = $rs->configure();
foreach (@axs) {
  isok("configure() <-> $_()",$get{$_},$cfg{$_});
}

# 2n+1..3n : set-access
foreach (@axs) {
  $got = $cfg{$_};
  if (defined($got) && $got =~ /^[-+]?[\d\.]+$/) {
    $val = 42;
  } else {
    $val = 'foobar';
  }
  # hack for boolean flags:
  if ($_ eq 'use_audio' || $_ eq 'running') {
    $val = 1;
  }
  # actual test
  isok("$_($val) [set]", $rs->$_($val), $val);
}

# 3n+1..4n : configure write-access
$rs->configure(%cfg);
foreach(@axs) {
  $val = safestr($cfg{$_});
  isok("configure($_=>$val,...) <-> $val",$get{$_},$cfg{$_});
}


# end of t/03_access.t
