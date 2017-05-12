$::VERSION = $::VERSION = 0.01;
use 5.00503;
use strict;
use Test::Simply tests => 1;
use Stable::Module;

my $first = '';
eval {
    $first = first { $_ > 3 } (1..10);
};
ok(($first == 4), qq{$^X @{[__FILE__]}});

__END__
