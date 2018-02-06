use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Simply tests => 1;
use Stable::Module;

my $bin = '';
eval {
    $bin = $Bin;
};
ok(($bin ne ''), qq{$^X @{[__FILE__]}});

__END__
