#!perl -T
#!perl -T
use Test::More tests => 5;
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

eval {
{  
   package validation_test_one_of_array_ref;
   use MooseX::AuthorizedMethodRoles;
   with 'test_role1';
   authorized_roles ping =>  {one_of=>{'test_role1'=>1,'test_role2'=>'2'}}, sub {
   return "ping test_one_of_pass";
};

}
};

ok(scalar($@),"validation_test_one_of_array_ref" );

eval {
{  
   package validation_test_required_array_ref;
   use MooseX::AuthorizedMethodRoles;
   with 'test_role1';
   authorized_roles ping =>  {required=>{'test_role1'=>1,'test_role2'=>'2'}}, sub {
   return "ping test_one_of_pass";
};

}
};

ok(scalar($@),"validation_test_required_array_ref" );

eval {
{  
   package validation_test_not_in_API;
   use MooseX::AuthorizedMethodRoles;
   with 'test_role1';
   authorized_roles ping =>  {not_API=>['test_role1','test_role2']}, sub {
   return "ping test_one_of_pass";
};

}
};

ok(scalar($@),"validation_test_not_in_API" );

eval{
{  
   package validation_test_API_extra_array_ref;
   use MooseX::AuthorizedMethodRoles;
   with 'test_role1';
   authorized_roles ping =>  {not_API=>['test_role1','test_role2'],
                              required=>['test_role1','test_role2']}, sub {
   return "ping test_one_of_pass";
};

}
};

ok(!scalar($@),"validation_test_API_extra_array_ref" );
