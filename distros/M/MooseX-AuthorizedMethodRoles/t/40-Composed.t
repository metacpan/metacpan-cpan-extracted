#!perl -T


use Test::More  tests => 4;
 
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
 
 # { package OtherRole;
  # use Moose::Role;
# };
 
{ package MyRole;
  use Moose::Role;
#  with 'OtherRole';
  with 'MooseX::Meta::Method::Role::Authorized';
};
 
 
{  
   package test_one_of_pass;
   use Moose;
   with 'test_role2';
   sub ping {
      return "ping test_one_of_pass";
   }
} 
{  
   package test_one_of_fail;
    use Moose;
   with 'test_role2';

   sub ping {
      return "ping test_one_of_fail";
   };
}


{  
   package test_required_pass;
   use Moose;
   with 'test_role2';
   sub ping {
      return "ping test_required_pass";
   }
} 
{  
   package test_required_fail;
    use Moose;
   with 'test_role2';

   sub ping {
      return "ping test_required_fail";
   };
}

my $meth = test_one_of_pass->meta->get_method('ping');
my $meth2 = test_one_of_fail->meta->get_method('ping');
my $meth3 = test_required_pass->meta->get_method('ping');
my $meth4 = test_required_fail->meta->get_method('ping');


MyRole->meta->apply($meth, rebless_params => {requires=>{ one_of => ['test_role2'] }});
MyRole->meta->apply($meth2, rebless_params => {requires=>{ one_of => ['test_role3'] }});
MyRole->meta->apply($meth3, rebless_params => {requires=>{ required => ['test_role2'] }});
MyRole->meta->apply($meth4, rebless_params => {requires=>{ required => ['test_role3'] }});


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

