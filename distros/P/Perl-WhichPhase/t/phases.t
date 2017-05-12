# $Id: phases.t,v 1.1 2002/01/07 15:00:51 jgsmith Exp $

BEGIN { print "1..10\n"; }

use Perl::WhichPhase qw- :in block -;

BEGIN {
  sub do_test ($$) {
    my($n,$f) = @_;
    if($f) {
      print "ok     $n\n";
    } else {
      print "not ok $n\n";
    }
  }

  do_test 1, in_BEGIN;
  do_test 2, block eq "BEGIN";
}

CHECK {
  do_test 3, in_CHECK;
  do_test 4, block eq "CHECK";
}

INIT {
  do_test 5, in_INIT;
  do_test 6, block eq "INIT";
}

END {
  do_test 9, in_END;
  do_test 10, block eq "END";
}

  do_test 7, in_CODE;
  do_test 8, !defined block;

1;
