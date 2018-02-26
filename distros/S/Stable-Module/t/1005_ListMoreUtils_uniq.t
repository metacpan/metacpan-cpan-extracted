use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..1\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my @uniq = ();
eval {
    @uniq = uniq(1,2,2,3,3,3,4,4,4,4);
};
ok((join(',',@uniq) eq '1,2,3,4'), qq{$^X @{[__FILE__]}});

__END__
