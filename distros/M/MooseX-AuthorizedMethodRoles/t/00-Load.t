#!perl -T
use Test::More tests => 3;
use Test::Moose::More;
use_ok('MooseX::AuthorizedMethodRoles');

{  
   package test;
   use MooseX::AuthorizedMethodRoles;
    
}

validate_class 'test' => ();