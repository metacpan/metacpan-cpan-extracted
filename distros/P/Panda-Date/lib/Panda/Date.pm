package Panda::Date;
use parent 'Panda::Export';
use 5.012;
use Panda::Time;
use Panda::Date::Rel;
use Panda::Date::Int;

our $VERSION = '3.1.0';

require Panda::XSLoader;
Panda::XSLoader::bootstrap('Panda::Date', $VERSION);

Panda::Export->import(
    E_OK         => 0,
    E_UNPARSABLE => 1,
    E_RANGE      => 2,
    SEC          => rdate_const("1s"),
    MIN          => rdate_const("1m"),
    HOUR         => rdate_const("1h"),
    DAY          => rdate_const("1D"),
    MONTH        => rdate_const("1M"),
    YEAR         => rdate_const("1Y"),
);

use overload
    '""'     => \&to_string,
    'bool'   => \&to_bool,
    '0+'     => \&to_number,
    '<=>'    => \&compare,
    'cmp'    => \&compare,
    '+'      => \&add_new,
    '+='     => \&add,
    '-'      => \&subtract_new,
    '-='     => \&subtract,
    '='      => sub { $_[0] },
    fallback => 1;

1;
