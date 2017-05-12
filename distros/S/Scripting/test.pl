# $Source: /Users/clajac/cvsroot//Scripting/test.pl,v $
# $Author: clajac $
# $Date: 2003/07/21 10:10:05 $
# $Revision: 1.10 $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Scripting;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $warned = 0;
$SIG{__WARN__} = sub { 
  my $warn = shift;
  do {print "ok 2\n";},return if($warn =~ /Signature database not found/);
  do {print "ok 3\n";},return if($warn =~ /Failed to open signature database/);
  print "ok 4\n" unless $warned; $warned = 1;
};

package Pkg1;
use Scripting::Expose;

sub new : Constructor {
  print "ok 5\n";
  return bless { foo => 1 }, __PACKAGE__;
}

sub test : InstanceMethod {
  my ($self, $arg) = @_;
  print $self->isa("Pkg1") ? "ok 6\n" : "not ok 6\n";
  print $arg eq "foo" ? "ok 7\n" : "not ok 7\n";
}

package Pkg2;
use Scripting::Expose;

sub test_foo : ClassMethod(as => 'test') {
  my ($self, $arg) = @_;
  print $self->isa("Pkg2") ? "ok 8\n" : "not ok 8\n";
  print $arg eq "bar" ? "ok 9\n" : "not ok 9\n";
}

sub Pkg3;
use Scripting::Expose;

sub test_bar : Function(as => 'test') {
  my ($arg) = @_;
  print $arg eq "baz" ? "ok 10\n" : "not ok 10\n";
}

package Pkg::Pkg4;
use Scripting::Expose as => "Pkg4";

sub test : ClassMethod {
  my ($self, $arg) = @_;
  print $self->isa("Pkg::Pkg4") ? "ok 11\n" : "not ok 11\n";
  print $arg eq "biz" ? "ok 12\n" : "not ok 12\n";
}  

package Pkg5;
use Scripting::Expose to => 'Pkg5';

sub test : ClassMethod {
  my ($self, $arg) = @_;
  print $self->isa("Pkg5") ? "ok 13\n" : "not ok 13\n";
  print $arg eq "foo" ? "ok 14\n" : "not ok 14\n";
}

package main;
use Scripting;

Scripting->init( with => "scripts/", allow => 'js', signfile => 'test.sign_db' );

Scripting->invoke("Pkg1Event");
Scripting->invoke("Pkg2Event");
Scripting->invoke("Pkg3Event");
Scripting->invoke("Pkg4Event");
Scripting->invoke(Pkg5 =>  "Pkg5Event");
