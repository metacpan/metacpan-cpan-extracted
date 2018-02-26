use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..1\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

eval q{
    say "";
};
if (not $@) {
    ok(1, qq{$^X @{[__FILE__]}});
}
else {
    ok(0, qq{$^X @{[__FILE__]}});
}

__END__
