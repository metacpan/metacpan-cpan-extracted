package Echo;
use strict;
use Test::More;
sub say {
    my $cb = pop;
    is(ref($cb), 'CODE', "The last arg is a code ref");

    my ($class, @args) = @_;
    $cb->($class, @args);
}
1;
