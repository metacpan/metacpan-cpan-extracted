package Panda::Date::Rel;
use 5.012;
use Panda::Date;

use overload '""'     => \&to_string,
             'bool'   => \&to_bool,
             '0+'     => \&to_number,
             'neg'    => \&negative_new,
             '<=>'    => \&compare, # based on to_sec()
             'eq'     => \&equals,  # based on full equality only
             '+'      => \&add_new,
             '+='     => \&add,
             '-'      => \&subtract_new,
             '-='     => \&subtract,
             '*'      => \&multiply_new,
             '*='     => \&multiply,
             '/'      => \&divide_new,
             '/='     => \&divide,
             '='      => sub { $_[0] },
             fallback => 1;
             
1;