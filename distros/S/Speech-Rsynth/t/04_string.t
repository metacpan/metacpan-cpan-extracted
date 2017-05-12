# -*- Mode: Perl -*-
# t/04_string.t : test file output from 'Say_String'

use vars qw($TEST_DIR);
$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

use Test;
BEGIN {
  plan tests => 2;
}

# load module & common subs
use Speech::Rsynth;
do "$TEST_DIR/common.plt";

# new object
$rs = Speech::Rsynth->new();
$rs->linear_filename("$TEST_DIR/out.raw");
$rs->au_filename("$TEST_DIR/out.au");

# generate files with 'Say_String()'
$rs->Start;
$rs->Say_String("[fu]");
$rs->Stop;

# 1..2 : files from string
fileok("Say_String / linear", "$TEST_DIR/out.raw", "$TEST_DIR/foo.raw");
fileok("Say_String / au",     "$TEST_DIR/out.au",  "$TEST_DIR/foo.au");
unlink("$TEST_DIR/out.raw", "$TEST_DIR/out.au");

# end of t/04_string.t
