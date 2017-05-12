package egClassMethodMaker;
use strict;
use warnings;

use Class::MethodMaker (
    new => "new",
    get_set => [qw( -eiffel
        prop1
        prop2
        prop3
        prop4
    )],
);

sub crunch {
    my ($self, $n) = @_;
    $n = 1 if $n < 1;
    my $sum = 0;
    while ($n--) {
        $self->set_prop1(1);
        $sum += $self->prop1;
    }
}

1;
