#perl
use Test::More;

use_ok 'Music::MelodicDevice::Arpeggiation';

subtest defaults => sub {
    my $mda = new_ok 'Music::MelodicDevice::Arpeggiation';# => [ verbose => 1 ];
    is $mda->duration, 1, 'duratiion';
    is $mda->type, 'up', 'type';
    is $mda->repeats, 1, 'repeats';
};

subtest arp => sub {
    my $mda = new_ok 'Music::MelodicDevice::Arpeggiation';# => [ verbose => 1 ];
    my $got = $mda->arp([60,64,67], 1, 'up');
    is_deeply $got, [['d32', 60],['d32', 64],['d32', 67]], 'arp';
    $got = $mda->arp([60,64,67], 1, 'down');
    is_deeply $got, [['d32', 67],['d32', 64],['d32', 60]], 'arp';
    $got = $mda->arp([60,64,67,69], 1, 'up');
    is_deeply $got, [['d24', 60],['d24', 64],['d24', 67], ['d24', 69]], 'arp';
    $mda->repeats(2);
    $got = $mda->arp([60,64,67], 1, 'up');
    is_deeply $got, [['d32', 60],['d32', 64],['d32', 67],['d32', 60],['d32', 64],['d32', 67]], 'arp';
    $mda->repeats(1);
    $got = $mda->arp([60,64,67], 0.5, 'up');
    is_deeply $got, [['d16', 60],['d16', 64],['d16', 67]], 'arp';
    # $mda->pattern([2,1,0]);
    # $got = $mda->arp([60,64,67]);
    # is_deeply $got, [['d16', 67],['d16', 64],['d16', 60]], 'arp';
};

subtest arp_type => sub {
    my $mda = new_ok 'Music::MelodicDevice::Arpeggiation';# => [ verbose => 1 ];
    my $got = $mda->arp_type;
    is ref($got), 'HASH', 'arp_type';
    $got = $mda->arp_type('up');
    is ref($got), 'CODE', 'arp_type';
    $mda->arp_type('foo', sub { [0,1] });
    $got = $mda->arp_type('foo');
    is ref($got), 'CODE', 'arp_type';
    $got = $mda->arp([60], 1, 'foo');
    is_deeply $got, [['d96', 60]], 'arp';
    $got = $mda->arp([60,64], 1, 'foo');
    is_deeply $got, [['d48', 60],['d48', 64]], 'arp';
    $got = $mda->arp([60,64,67], 1, 'foo');
    is_deeply $got, [['d32', 60],['d32', 64],['d32', 60]], 'arp';
};

done_testing();
