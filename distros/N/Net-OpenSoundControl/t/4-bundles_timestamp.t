use Test::More tests => 7;

use Net::OpenSoundControl;

my $t = time();

my $bundles = [
    ['#bundle', 0,         ['/test/1', 'i', 42]],
    ['#bundle', 0.5,       ['/test/2', 'i', 42]],
    ['#bundle', 1,         ['/test/3', 'i', 42]],
    ['#bundle', $t,        ['/test/4', 'i', 42]],
    ['#bundle', $t + 1,    ['/test/5', 'i', 42]],
    ['#bundle', $t + 0.42, ['/test/6', 'i', 42]],
    ['#bundle', $t + 0.5,  ['/test/6', 'i', 42]]];

foreach my $b (@$bundles) {
    my $bnew = Net::OpenSoundControl::decode(Net::OpenSoundControl::encode($b));

    ok($b->[1] eq $bnew->[1]);
}
