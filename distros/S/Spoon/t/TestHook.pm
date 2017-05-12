package TestHook;
use Spoon::Base -Base;

sub number {
    42;
}

sub other {
    45;
}

package TestHookA;
use base 'Spoon::Base';

sub one {
    47;
}

package Tweak;
use base 'TestHookA';

sub two {
    my $hook = pop;
    $hook->cancel;
    48;
}
