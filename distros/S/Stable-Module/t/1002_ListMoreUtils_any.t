use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..4\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my $any = '';

$any = any {$_} 1,1,1,1;
ok($any, qq{any {\$_} 1,1,1,1 $^X @{[__FILE__]}});

$any = any {$_} 0,0,0,0;
ok((not $any), qq{any {\$_} 0,0,0,0 $^X @{[__FILE__]}});

$any = any {$_} 0,0,0,1;
ok($any, qq{any {\$_} 0,0,0,1 $^X @{[__FILE__]}});

$any = any {$_} 1,1,1,0;
ok($any, qq{any {\$_} 1,1,1,0 $^X @{[__FILE__]}});

__END__
