use warnings;
use strict;

use Test::More;

use RPi::DigiPot::MCP4XXXX;

my $mod = 'RPi::DigiPot::MCP4XXXX';

{ # bytes

    my $b = $mod->_bytes(1, 1, 1);

    is $b->[0], 17, "cmd byte ok";
    is $b->[1], 1,  "data  byte ok";

    $b = $mod->_bytes(30, 10, 17);

    is $b->[0], 490, "cmd byte ok";
    is $b->[1], 17,  "data  byte ok";

    $b = $mod->_bytes(0b1111, 0b1111, 255);

    is $b->[0], 255, "cmd byte ok";
    is $b->[1], 255, "data  byte ok";

    # my $x = 0;
    # for (@$b){
    #     printf("$x b: %b\n", $b->[$x]);
    #     printf("$x x: %x\n", $b->[$x]);
    #     printf("$x d: %d\n", $b->[$x]);
    #     $x++;
    # }
}

done_testing();
