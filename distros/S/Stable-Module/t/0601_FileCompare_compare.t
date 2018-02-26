use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..2\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
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
