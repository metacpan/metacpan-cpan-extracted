#perl
use Test::More;

use_ok 'Music::MelodicDevice::Arpeggiation';

subtest defaults => sub {
    my $mda = new_ok 'Music::MelodicDevice::Arpeggiation';# => [ verbose => 1 ];
    is $mda->duration, 1, 'duratiion';
    is_deeply $mda->pattern, [0,1,2], 'pattern';
    is $mda->repeats, 1, 'repeats';
};

subtest arp => sub {
    my $mda = new_ok 'Music::MelodicDevice::Arpeggiation';# => [ verbose => 1 ];
    my $got = $mda->arp([60,64,67]);
    is_deeply $got, [['d32', 60],['d32', 64],['d32', 67]], 'arp';
    my $got = $mda->arp([60,64,67]);
    is_deeply $got, [['d32', 60],['d32', 64],['d32', 67]], 'arp';
    $mda->repeats(2);
    $got = $mda->arp([60,64,67]);
    is_deeply $got, [['d32', 60],['d32', 64],['d32', 67],['d32', 60],['d32', 64],['d32', 67]], 'arp';
    $mda->repeats(1);
    $mda->duration(0.5);
    $got = $mda->arp([60,64,67]);
    is_deeply $got, [['d16', 60],['d16', 64],['d16', 67]], 'arp';
    $mda->pattern([2,1,0]);
    $got = $mda->arp([60,64,67]);
    is_deeply $got, [['d16', 67],['d16', 64],['d16', 60]], 'arp';
};

done_testing();