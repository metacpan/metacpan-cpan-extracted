use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Simply tests => 1;
use Stable::Module;

my $hostname = '';
eval {
    $hostname = hostname();
};
ok(($hostname ne ''), qq{$^X @{[__FILE__]}});

__END__
