use strict;
use warnings;

use RPi::Pin;
use Test::More;

my $mod = 'RPi::Pin';

if (! $ENV{PI_BOARD}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
}

{# pin

    my $pin = $mod->new(18, "blah");

    is $pin->comment, 'blah', "comment in new ok";
    is $pin->comment('test'), 'test', "comment() sets and gets ok";

    is $pin->mode, 0, "pin mode is INPUT by default";
    is $pin->read, 0, "pin status is LOW by default";

    $pin->mode(1);

    is $pin->mode, 1, "pin mode is OUTPUT ok";
    
    is $pin->read, 0, "pin status is LOW after going OUTPUT mode";

    if (! $ENV{NO_BOARD}){

        $pin->write(1);
        
        is $pin->read, 1, "pin status HIGH after write(1)";

        $pin->write(0);
        
        is $pin->read, 0, "pin status back to LOW after write(0)";
       
        $pin->mode(0);
    
        is $pin->mode, 0, "pin mode back to INPUT";
    }
}

done_testing();
