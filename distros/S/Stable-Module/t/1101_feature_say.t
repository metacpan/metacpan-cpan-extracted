use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Simply tests => 1;
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
