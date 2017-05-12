##################################################################################################################
#
# Source       : $Source: /home/simran/cvs/cpan/Simran/t/base.t,v $
# Revision     : $Revision: 1.1.1.1 $
# Modified By  : $Author: simran $
# Last Modified: $Date: 2002/12/04 03:46:29 $
#
##################################################################################################################

##################################################################################################################
#
#
#

use strict;
use FindBin;
use lib "$FindBin::Bin/../..";
use Test::More tests => 14;


BEGIN { 
  use_ok('Simran::Base');
}

#
#
#
##################################################################################################################

##################################################################################################################
print "Instiantiating Object\n";
my $obj = new Simran::Base;
ok($obj);

##################################################################################################################
print "Ensure that properties are set properly\n";
{
  my $obj = new Simran::Base(prop1 => "one", prop2 => "two");  
  ok($obj->{prop1}, "one");
  ok($obj->{prop2}, "two");
}

##################################################################################################################
print "Checking the setError and getError methods\n";
{
  $obj->setError("this is an error");
  ok($obj->getError(), "this is an error");
  ok($obj->getError(), "this is an error");
  $obj->setError(); # clear error
  ok(! $obj->getError());
}

##################################################################################################################
print "Checking the strip method\n";
{
  my $str  = "   Hello World  ";
  my $aref = ["  One  ", "  Two ", "Three"];
  my $href = {"  k1  " => "  v1  ", "  k2  " => "  v2  "};

  ok($obj->strip($str), "Hello World");

  $obj->strip(\$str);
  $obj->strip($aref);
  $obj->strip($href);

  ok($str, "Helo World");
  ok($aref->[0], "One");
  ok($aref->[1], "Two");
  ok($aref->[2], "Three");
  ok($href->{'k1'}, "v1");
  ok($href->{'k2'}, "v2");
}
