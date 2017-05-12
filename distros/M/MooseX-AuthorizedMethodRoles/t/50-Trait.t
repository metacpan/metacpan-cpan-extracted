#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 5;
 
use_ok('MooseX::Meta::Method::Role::Authorized');
 {
   package test_role1;
   use Moose::Role;
   has 'nothing_r1 '=> (is => 'ro',default=>'role 1');
   
}
{
   package test_role2;
   use Moose::Role;
   has 'nothing_r2' => (is => 'ro',default=>'role 2');
   
}
{
   package test_role3;
   use Moose::Role;
   has 'nothing_r3' => (is => 'ro',default=>'role 3');
   
}
use Moose;
my $method_metaclass = Moose::Meta::Class->create_anon_class
  (
   superclasses => ['Moose::Meta::Method'],
   roles => ['MooseX::Meta::Method::Role::Authorized'],
   cache => 1,
  );
 


{ package test_all_pass_fail;
  use Moose;
  with ('test_role1','test_role3');
  
  my $m = $method_metaclass->name->wrap
    (
     sub {
         my $self = shift;
         return ' required_pass '.shift;
     },
     package_name => 'test_all_pass_fail',
     name => 'ping_required_pass',
     requires =>{ required =>['test_role3']}
    );
  __PACKAGE__->meta->add_method('ping_required_pass',$m);
 
  my $n = $method_metaclass->name->wrap
    (
     sub {
         my $self = shift;
         return 'one_of_pass'.shift;
     },
     package_name => 'test_all_pass_fail',
     name => 'ping_one_of_pass',
     requires =>{ one_of =>['test_role1','test_role2']}
    );
  __PACKAGE__->meta->add_method('ping_one_of_pass',$n);
 
   my $o = $method_metaclass->name->wrap
    (
     sub {
         my $self = shift;
         return ' one_of_fail '.shift;
     },
     package_name => 'test_all_pass_fail',
     name => 'ping_one_of_fail',
     requires =>{ one_of =>['test_role2','test_role4']}
    );
  __PACKAGE__->meta->add_method('ping_one_of_fail',$o);
  
  my $p = $method_metaclass->name->wrap
    (
     sub {
         my $self = shift;
         return ' required_fail '.shift;
     },
     package_name => 'test_all_pass_fail',
     name => 'ping_required_fail',
     requires =>{ required =>['test_role2']}
    );
  __PACKAGE__->meta->add_method('ping_required_fail',$p);
  
};
 
my $object1 = test_all_pass_fail->new();
 
ok($object1->ping_required_pass('test1'),'ping_required_pass');
ok($object1->ping_one_of_pass('test1'),'ping_one_of_pass');

eval {
  $object1->ping_one_of_fail('test1');
};

ok(scalar($@),"ping_one_of_fail pass");

eval {
  $object1->ping_required_fail('test1');
};

ok(scalar($@),"ping_required_fail pass");
 
1;