package SubClass;

BEGIN { require PlainClass; our @ISA = 'PlainClass' }
use Object::Tiny::Lvalue qw( foo bar );

1;
