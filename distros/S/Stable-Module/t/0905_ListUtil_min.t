$::VERSION = $::VERSION = 0.01;
use 5.00503;
use strict;
use Test::Simply tests => 1;
use Stable::Module;

my $min = '';
eval {
    $min = min(1..10);
};
ok(($min == 1), qq{$^X @{[__FILE__]}});

__END__
