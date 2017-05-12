package My::Injected;
use strict;
use warnings;
use POE;
use base qw(POE::Sugar::Attributes);

my $MAIN_ALIAS = 'main_alias';

my %EventRegistry = (
    my_injected_injected => 0,
    say_hi              => 0,
);

sub injected
    :Recurring(Interval => 0.01, Name => 'my_injected_injected')
{
    $EventRegistry{$_[STATE]}++;
    $_[KERNEL]->delay($_[STATE]);
    $_[KERNEL]->state($_[STATE]);
}

sub inject {
    my ($cls,$poe_kernel) = @_;
    POE::Sugar::Attributes->wire_current_session($poe_kernel);
    $poe_kernel->post($MAIN_ALIAS, 'say_hi');
}


package My::Controller;
use strict;
use warnings;
use POE qw(Session);
use Test::More;
use base qw(POE::Sugar::Attributes);

sub init :Start {
    My::Injected->inject($_[KERNEL]);
}

sub say_hi :Event {
    $EventRegistry{$_[STATE]}++;
}

sub stop :Stop {
    note "Done!";
}

POE::Session->create(
    inline_states => POE::Sugar::Attributes->inline_states(__PACKAGE__, $MAIN_ALIAS)
);

POE::Kernel->run();

while (my ($state,$called) = each %EventRegistry) {
    ok($called, "State '$state' invoked as expected");
}

done_testing();