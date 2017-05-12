package egObjectLocalVars;
use strict;
use warnings;
use Object::LocalVars;

give_methods our $self;

our $prop1 : Pub;
our $prop2 : Pub;
our $prop3 : Pub;
our $prop4 : Pub;

sub crunch : Method {
    my $n = shift;
    $n = 1 if $n < 1;
    my $sum = 0;
    while ($n--) {
        no warnings 'void';
        $prop1 = 1;
        $sum += $prop1;
    }
}

1;

