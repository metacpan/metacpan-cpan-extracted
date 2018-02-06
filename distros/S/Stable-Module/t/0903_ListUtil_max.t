use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Simply tests => 1;
use Stable::Module;

my $max = '';
eval {
    $max = max(1..10);
};
ok(($max == 10), qq{$^X @{[__FILE__]}});

__END__
