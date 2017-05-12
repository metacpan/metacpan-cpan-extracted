#!perl -T


use Test::More;

eval {
   require Moose::Util;
};

if ($@){
   plan skip_all =>qw(Skipped all. 'Moose::Util' not installed.  Not required but this Module is not much use wihtout it!)

}
else {
  plan tests => 5;
}

use_ok('MooseX::AuthorizedMethodRoles');

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

{  
   package instance_test_one_of;
   use MooseX::AuthorizedMethodRoles;

   sub BUILD {
      my $self = shift;
      my ($attr) = @_;
      Moose::Util::apply_all_roles($self,("test_role1",=>$attr));
   }
   
   authorized_roles ping =>  {one_of=>['test_role1','test_role2']}, sub {
       return "ping instance_test_one_of";
   };
   
   has 'a_role'=> (is => 'ro',default=>'test_role1');
   
}



{  
   package instance_test_one_of_fail;
   use MooseX::AuthorizedMethodRoles;

   sub BUILD {
      my $self = shift;
      my ($attr) = @_;
      
     
      Moose::Util::apply_all_roles($self,("test_role3",=>$attr));
 }
   authorized_roles ping =>  {one_of=>['test_role1','test_role2']}, sub {
       return "ping instance_test_one_of_fail";
   };
   
   has 'a_role'=> (is => 'ro',default=>'test_role1');
   
}


{  
   package instance_test_required;
   use MooseX::AuthorizedMethodRoles;

   sub BUILD {
      my $self = shift;
      my ($attr) = @_;
      Moose::Util::apply_all_roles($self,("test_role1",=>$attr));
   }
   
   authorized_roles ping =>  {required=>['test_role1']}, sub {
       return "ping instance_test_required";
   };
   
   has 'a_role'=> (is => 'ro',default=>'test_role1');
   
}



{  
   package instance_test_required_fail;
   use MooseX::AuthorizedMethodRoles;

   sub BUILD {
      my $self = shift;
      my ($attr) = @_;
      
     
      Moose::Util::apply_all_roles($self,("test_role3",=>$attr));
 }
   authorized_roles ping =>  {required=>['test_role1','test_role2']}, sub {
       return "ping instance_test_required_fail";
   };
   
   has 'a_role'=> (is => 'ro',default=>'test_role3');
   
}


my $test1 = instance_test_one_of->new();
ok($test1->ping());


my $test2 = instance_test_one_of_fail->new();
eval {
   $test2->ping();
};

ok(scalar($@),"instance_test_one_of_fail pass");

my $test3 = instance_test_required->new();
ok($test3->ping());


my $test4 = instance_test_required_fail->new();
eval {
   $test4->ping();
};

ok(scalar($@),"instance_test_one_of_fail pass");

