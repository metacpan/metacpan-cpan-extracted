use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Simply tests => 1;
use Stable::Module;

my $first = '';
eval {
    $first = first { $_ > 3 } (1..10);
};
ok(($first == 4), qq{$^X @{[__FILE__]}});

__END__
