use strict;
use warnings;

use lib 't/';

use RPi::WiringPi;
use RPiTest;
use RPi::Const qw(:all);
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

my $pi = $mod->new(label => 't/153-sig_handlers.t', shm_key => 'rpit');

my $sh = $pi->signal_handlers;

# We trap INT and TERM only. __DIE__ is intentionally NOT trapped: hardware
# cleanup on a crash or normal exit is handled by END/DESTROY, so a caught
# eval { die } never disturbs the pins.

is keys(%{ $sh }), 2, "there are two sig handlers set (INT, TERM) ok";
ok ! exists $sh->{'__DIE__'}, "__DIE__ is not trapped";

for ('INT', 'TERM'){
    is exists($sh->{$_}), 1, "$_ is a valid handler";
    my $uuid = $pi->uuid;
    is ref $sh->{$_}{$uuid}, 'CODE', "$_ has a handler for UUID $uuid";
    is ref $SIG{$_}, 'CODE', "\$SIG{$_} is installed as a code ref";
}

$pi->cleanup;

$sh = $pi->signal_handlers;

# cleanup() releases the object's INT/TERM entries, and with the last object
# gone, the pre-object dispositions (here, none == DEFAULT) are restored

is keys(%{ $sh }), 0, "after proper cleanup, all sig handler entries are released";
ok ! exists $sh->{'__DIE__'}, "__DIE__ is still not trapped after cleanup()";

for ('INT', 'TERM'){
    ok ! exists $sh->{$_}, "$_ handler entry removed after clean cleanup()";
    is $SIG{$_}, 'DEFAULT', "\$SIG{$_} restored to its pre-object disposition";
}

{ # A pre-existing CODE handler is restored after the last cleanup

    my $called = 0;
    my $custom = sub { $called++ };
    local $SIG{INT} = $custom;

    my $obj = $mod->new(label => 't/153-code-restore', shm_key => 'rpit');
    is ref $SIG{INT}, 'CODE', "class handler installed while object is live";

    $obj->cleanup;
    is $SIG{INT}, $custom, "pre-existing CODE INT handler restored after cleanup";
}

{ # A pre-existing non-CODE disposition ('IGNORE') is restored, not dropped

    local $SIG{TERM} = 'IGNORE';

    my $obj = $mod->new(label => 't/153-ignore-restore', shm_key => 'rpit');
    is ref $SIG{TERM}, 'CODE', "class handler replaces 'IGNORE' while object is live";

    $obj->cleanup;
    is $SIG{TERM}, 'IGNORE', "pre-existing 'IGNORE' TERM disposition restored after cleanup";
}

{ # Handlers persist until the LAST object is cleaned up

    my $obj1 = $mod->new(label => 't/153-multi-1', shm_key => 'rpit');
    my $obj2 = $mod->new(label => 't/153-multi-2', shm_key => 'rpit');

    $obj1->cleanup;

    my $handlers = $obj2->signal_handlers;
    ok exists $handlers->{INT}{$obj2->uuid},
        "second object's INT entry remains after first object's cleanup";
    is ref $SIG{INT}, 'CODE', "\$SIG{INT} still installed while an object remains";

    $obj2->cleanup;
    is $SIG{INT}, 'DEFAULT', "\$SIG{INT} restored once the last object is cleaned";
}

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();
