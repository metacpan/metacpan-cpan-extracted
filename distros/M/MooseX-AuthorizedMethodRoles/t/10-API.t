#!perl -T
use Test::More tests => 8;
use Test::Moose::More;
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
   package test_one_of_pass;
   use MooseX::AuthorizedMethodRoles;
   with 'test_role1';
   authorized_roles ping =>  {one_of=>['test_role1','test_role2']}, sub {
   return "ping test_one_of_pass";
};

}
{  
   package test_one_of_fail;
   use MooseX::AuthorizedMethodRoles;
   with 'test_role3';
   authorized_roles ping =>  {one_of=>['test_role1','test_role2']}, sub {
   return "ping test_one_of_fail";
};
}

{  
   package test_required_pass;
   use MooseX::AuthorizedMethodRoles;
     with 'test_role1';
   authorized_roles ping =>  { required =>['test_role1']}, sub {
      return "ping test_required_pass";
   };
}
{  
   package test_required_fail;
   use MooseX::AuthorizedMethodRoles;
     with 'test_role2';
   authorized_roles ping =>  { required =>['test_role1']}, sub {
    return "ping test_required_fail";
};

}
{  
   package test_required_pass_2;
   use MooseX::AuthorizedMethodRoles;
     with qw(test_role1 test_role2);
   authorized_roles ping =>  { required =>['test_role1','test_role2']}, sub {
     return "ping test_required_pass_2";
   };
}
{  
   package test_required_fail_2;
   use MooseX::AuthorizedMethodRoles;
     with  qw(test_role1 test_role2);
   authorized_roles ping =>  { required =>['test_role1','test_role2','test_role3']}, sub {
      return "ping test_required_fail_2";
   };
}

{  
   package test_all;
   use MooseX::AuthorizedMethodRoles;
    with  qw(test_role1 test_role3);
   authorized_roles ping =>  { required =>['test_role1'],
								one_of=>['test_role2','test_role3']}, sub {
   return "ping test_all";
};

}

my $test1 = test_one_of_pass->new();
ok($test1->ping(),"one_of pass");

my $test2 = test_one_of_fail->new();

eval {
   $test2->ping();
};


ok(scalar($@),"test_one_of_fail");

my $test3 = test_required_pass->new();

ok($test3->ping(),"test_required_pass");

my $test4 = test_required_fail->new();

eval {
   $test4->ping();
};

 
ok(scalar($@),"test_required_fail");

my $test5 = test_required_pass_2->new();

ok($test5->ping(),"test_required_pass_2");

my $test6 = test_required_fail_2->new();

eval {
   $test6->ping();
};

ok(scalar($@),"test_required_fail_2");

my $test7 = test_all->new();

ok($test7->ping(),"test_all");
