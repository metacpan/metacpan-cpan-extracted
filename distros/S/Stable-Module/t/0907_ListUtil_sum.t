$::VERSION = $::VERSION = 0.01;
use 5.00503;
use strict;
use Test::Simply tests => 1;
use Stable::Module;

my $sum = 0;
eval {
    $sum = sum(1..10);
};
ok(($sum == 55), qq{$^X @{[__FILE__]}});

__END__
