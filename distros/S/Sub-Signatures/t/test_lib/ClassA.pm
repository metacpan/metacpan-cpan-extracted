package ClassA;

use strict;
use warnings;
use Sub::Signatures qw/methods/;

sub new { bless {} => shift }

sub foo($class, $bar) {
    if ( 'ARRAY' eq ref $bar ) {
        return sprintf "arrayref with %d elements" => scalar @$bar;
    }
    elsif ( 'HASH' eq ref $bar ) {
        $bar->{this} = 1; 
        return $bar;
    }
    else {
        die "Must be array or hash";
    }
}

sub bar($class, $bar) {
    $bar;
}

sub bar(fallback) {
    return ['fallback', @_];
}

sub match($class, $bar) {
    $bar;
}

sub subref ($self, $foo) {
    return sub ($bar) {
        return "$foo $bar";
    }
}

1;
