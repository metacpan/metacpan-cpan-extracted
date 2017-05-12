package Panda::Date::Int;
use 5.012;
use Panda::Date;

use overload '""'     => \&to_string,
             'bool'   => \&to_bool,
             '0+'     => \&to_number,
             '<=>'    => \&compare, # for idates - based on duration
             'eq'     => \&equals,  # absolute matching (from == from and till == till)
             '+'      => \&add_new,
             '+='     => \&add,
             '-'      => \&subtract_new,
             '-='     => \&subtract,
             'neg'    => \&negative_new,
             fallback => 1;

1;