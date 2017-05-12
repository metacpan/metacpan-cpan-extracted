# -*- Mode: Perl -*-
# t/06_audio.t : test audio output

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
$rs->use_audio(1);

# 1: test Say_String
print STDERR ("\n\n",
	      "*****************************************************************\n",
	      "*              Testing Say_String() Method                      *\n",
	      "*            You should hear some audio output!                 *\n",
	      "*****************************************************************\n\n");
$rs->Start;
$rs->Say_String("[DIs Iz V test]");
isok("Stop()", $rs->Stop);

# 2: test Say_File
$rs->Start;
open(IN,"<$TEST_DIR/test.txt") or die("couldn't open '$TEST_DIR/test.txt' for read: $!");
print STDERR ("\n\n",
	      "*****************************************************************\n",
	      "*                Testing Say_File() Method                      *\n",
	      "*            You should hear more audio output!                 *\n",
	      "*****************************************************************\n\n");
$rs->Say_File(IN);
isok("Stop()",$rs->Stop);
close(IN);

# end of t/06_audio.t
