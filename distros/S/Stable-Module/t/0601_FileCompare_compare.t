use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Simply tests => 2;
use Stable::Module;

my $compare = 0;

eval {
    $compare = compare(__FILE__,__FILE__);
};
ok((not $compare), qq{compare(__FILE__,__FILE__) $^X @{[__FILE__]}});

eval {
    $compare = compare('0101_Cwd_cwd.t',__FILE__);
};
ok($compare, qq{compare('0101_Cwd_cwd.t',__FILE__) $^X @{[__FILE__]}});

__END__
