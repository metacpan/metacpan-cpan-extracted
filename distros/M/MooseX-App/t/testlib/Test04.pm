package Test04;

#use Moose;
use MooseX::App;
extends qw(Test04Base);

option 'test1' => (
    is              => 'rw',
    isa             => 'Int',
);

option '+test2' => ();

1;