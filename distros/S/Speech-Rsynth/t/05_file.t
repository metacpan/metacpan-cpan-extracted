# -*- Mode: Perl -*-
# t/05_file.t : test file output from 'Say_File'

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

# generate files with 'Say_File()'
open(FOO,"<$TEST_DIR/foo.txt") or die("open failed for test source-file '$TEST_DIR/foo.txt': $!");
$rs->Start;
$rs->Say_File(FOO);
$rs->Stop;
close(FOO);

# 3..4 : files from FH
fileok("Say_File / linear", "$TEST_DIR/out.raw", "$TEST_DIR/foo.raw");
fileok("Say_File / au",     "$TEST_DIR/out.au",  "$TEST_DIR/foo.au");
unlink("$TEST_DIR/out.raw", "$TEST_DIR/out.au");

# end of t/05_file.t
