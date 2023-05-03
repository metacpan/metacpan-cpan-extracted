#!/usr/local/bin/perl -w
#
# Regression tests for code used by table walking

require 5.003;

use strict;

use BER;
use SNMP_Session;

&ic_test;
1;

sub ic_test () {
  ic_test_1 ("1.2.3","1.2.4",-1);
  ic_test_1 ("1.2.3","1.2.3",0);
  ic_test_1 ("1.2.4","1.2.3",1);
  ic_test_1 ("1.2.29.1","1.2.3.2",1);
  ic_test_1 ("1.2.29.1","1.2.3",1);
  ic_test_1 ("1.2.29","1.2.3.32",1);
}

sub ic_test_1 ($$$) {
  my ($oid1, $oid2, $wanted) = @_;
  my $result;
  die "index_compare(\"$oid1\",\"$oid2\") == $result, should be $wanted"
       unless ($result = index_compare ($oid1,$oid2)) == $wanted;
}
