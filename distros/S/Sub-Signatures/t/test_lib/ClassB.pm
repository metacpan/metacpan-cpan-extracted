package ClassB;
use base 'ClassA';

use strict;
use warnings;
use Sub::Signatures qw/methods/;

sub match($class, $bar, $foo) {
    return ('ARRAY' eq ref $bar)
        ? (@$bar == grep $_ =~ $foo => @$bar)
        : $bar =~ $foo;
}

sub match($class, $bar)
{ $bar }

1;
