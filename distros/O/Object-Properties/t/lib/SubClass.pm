package SubClass;

BEGIN { require PlainClass; our @ISA = 'PlainClass' }
use Object::Properties qw( foo bar );

1;
