package ClassA::Subclass;
use base 'ClassA';

use strict;
use warnings;
use Sub::Signatures qw/methods/;

sub match($class, $bar, $foo) {
    if ('ARRAY' eq ref $bar) {
        return @$bar == grep $_ =~ $foo => @$bar;
    }
    return $bar =~ $foo;
}

1;
