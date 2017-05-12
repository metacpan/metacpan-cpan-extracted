#!/usr/bin/env perl
#
#  Ugly Test for REXP creation
#  Work in progress...
#
#  Based on PHP tests for php Rserve client 
#

use Rserve;
use Rserve::Connection;
use Rserve::REXP::Integer;

use Data::Dumper;
use strict;

do 'config.pl';

#function testBinary($values, $type, $options = array(), $msg = '') {

sub testBinary(@) {
  my $argc = @_;

  print "$argc\n";
  my $values = shift;

#  print ref($values);
#  print Dumper($values);

  my $type = shift;
  my $options = ();
  my $msg = "";
  if ($argc == 3) {
    $options = shift;
  }
  elsif ($argc == 4) {
    $msg = shift;
  }

  print 'Test '.$type.' '.$msg."\n";

  my $cn = 'Rserve::REXP::'.$type;
  
  print "cn = $cn \n";

  my $r = new $cn();

  print "r is a " . ref($r) . "[$r]\n";
  
  my $tt  = lc($type);
  
  if ( $r->isVector()) {
    print "r is a Vector\n";
    if ($r -> isList() && @$options['named']) {
      print "r is a List\n";
      $r->setValues($values, Rserve::TRUE);                        
    } 
    else {
      $r->setValues($values);
    }
  } 
  else {
    $r->setValue($values);
  }



  my $bin = Rserve::Parser::createBinary($r);

  print "bin = ";
  print Dumper($bin);
  print "end bin\n";

  print "debug: \n";
  print Dumper(Rserve::Parser::parseDebug($bin, 0));
  print "end debug\n";

  my $r2 = Rserve::Parser::parseREXP($bin, 0);
  
  print "r2 = ";
  print Dumper($r2);
  print "end r2\n";

  my $cn2 = ref($r2);
  if ( lc($cn2) != lc(ref($cn))) {
    print 'Different classes';
    return Rserve::FALSE;
  } 
  else {
    print "Class Type ok\n";
    print "cn = $cn\n";
    print "cn2 = $cn2\n";
  }
}

print "Test 1: ----------------------------------------\n";
testBinary( [1,2,3], 'Integer'  );

print "Test 2: ----------------------------------------\n";

testBinary([1.1,2.2,3.3], 'Double'  );

print "Test 3: ----------------------------------------\n";

testBinary([Rserve::TRUE, Rserve::FALSE, Rserve::TRUE, []], 'Logical');
