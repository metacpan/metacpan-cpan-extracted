# -*- Mode: Perl -*-
# t/02_basic.t : test basic methods

use vars qw($TEST_DIR);
$TEST_DIR = './t';
#use lib qw(../blib/lib); $TEST_DIR = '.'; # for debugging

# change 'tests => 1' to 'tests => last_test_to_print';
use Test;
BEGIN { plan tests => 10 };

# 1: load module
use Speech::Rsynth;
do "$TEST_DIR/common.plt";
isok("use",1);

# 2 : new object
$rs = Speech::Rsynth->new();
isok("new()",$rs);

# 3 : dummy 'configure()'
$rc = $rs->Configure_Dummy();
isok("Configure_Dummy()",defined($rc));

# 4 : Start()
undef($rc);
$rc = $rs->Start();
isok("Start()",$rc);

# 5 : Say_String
$rs->Say_String('');
isok("Say_String('')",1);

# 6 : Stop
undef($rc);
$rc = $rs->Stop;
isok("Stop()",$rc);


# 7 : Start()
undef($rc);
$rc = $rs->Start();
isok("2nd Start()",$rc);

# 8 : Say_String
$rs->Say_String("");
isok("2nd Say_String('')",1);

# 9 : Stop
undef($rc);
$rc = $rs->Stop;
isok("2nd Stop()",$rc);


# 10 : undef
undef($rs);
isok("DESTROY()",(!defined($rs)));

# end of t/02_basic.t
