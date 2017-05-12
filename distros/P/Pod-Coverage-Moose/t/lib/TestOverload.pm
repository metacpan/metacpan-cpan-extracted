package TestOverload;
use Moose::Role;
use if !eval { require Moose; Moose->VERSION('2.1300') },
    'MooseX::Role::WithOverloading';

use overload
    q{""} => sub { },
    fallback => 1;

sub foo { };

1;
