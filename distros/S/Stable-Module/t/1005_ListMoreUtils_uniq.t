$::VERSION = $::VERSION = 0.01;
use 5.00503;
use strict;
use Test::Simply tests => 1;
use Stable::Module;

my @uniq = ();
eval {
    @uniq = uniq(1,2,2,3,3,3,4,4,4,4);
};
ok((join(',',@uniq) eq '1,2,3,4'), qq{$^X @{[__FILE__]}});

__END__
