use strict;
use warnings;
use Test::More;

use RPi::HCSR04;

if (! $ENV{PI_BOARD}){
    plan skip_all => "not a Pi board: PI_BOARD not set";
    exit;
}

my $mod = 'RPi::HCSR04';

{
    my $o = $mod->new(23, 24);

    my $ok = eval { $mod->new; 1; };
    is $ok, undef, "new() dies with no params";
    like $@, qr/new\(\) requires/, "...error ok";

    $ok = eval { $mod->new(23); 1; };
    is $ok, undef, "new() dies with only a single param";
    like $@, qr/new\(\) requires/, "...error ok";

}

done_testing();
