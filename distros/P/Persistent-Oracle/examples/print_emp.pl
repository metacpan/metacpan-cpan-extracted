#!/usr/bin/perl -w
########################################################################
# File:     subclass.pl
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: print_emp.pl,v 1.2 2000/02/10 02:54:31 winters Exp winters $
#
# An example script that performs a simple query and prints the results.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

use strict;

use Persistent::Oracle;
use English;  # import readable variable names like $EVAL_ERROR

my $emp;

eval {  ### in case an exception is thrown ###

  ### allocate a persistent object ###
  $emp = new Persistent::Oracle('dbi:Oracle:testdb', 'scott', 'tiger', 'emp');

  ### define attributes of the object ###
  $emp->add_attribute('empno',    'ID',         'Number',   undef, 4);
  $emp->add_attribute('ename',    'Persistent', 'VarChar',  undef, 10);
  $emp->add_attribute('job',      'Persistent', 'VarChar',  undef, 9);
  $emp->add_attribute('mgr',      'Persistent', 'Number',   undef, 4);
  $emp->add_attribute('hiredate', 'Persistent', 'DateTime', undef);
  $emp->add_attribute('sal',      'Persistent', 'Number',   undef, 7, 2);
  $emp->add_attribute('comm',     'Persistent', 'Number',   undef, 7, 2);
  $emp->add_attribute('deptno',   'Persistent', 'Number',   undef, 2);

  ### query the datastore for some objects ###
  $emp->restore_where(qq(
			 sal > 1000
			 and job = 'CLERK'
			 and ename LIKE 'M%'
                        ), "sal DESC, ename");
  while ($emp->restore_next()) {
    printf "ename = %s, emp# = %s, sal = %s, hiredate = %s\n",
    $emp->ename, $emp->empno, $emp->sal, $emp->hiredate;
  }
};

if ($EVAL_ERROR) {  ### catch those exceptions! ###
  print "An error occurred: $EVAL_ERROR\n";
}
