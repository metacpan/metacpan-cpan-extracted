package Number::Object::Filter::Comma;

use strict;
use warnings;
use base 'Number::Object::Filter';

sub filter {
    my($class, $c, $value) = @_;
    local $_ = $value;
    1 while s/((?:\A|[^.0-9])[-+]?\d+)(\d{3})/$1,$2/s;
    return $_;
}

1;
