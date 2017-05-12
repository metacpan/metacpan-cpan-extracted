$::VERSION = $::VERSION = 0.01;
use 5.00503;
use strict;
use Test::Simply tests => 1;
use Stable::Module;

my $time = time;
my @time = localtime($time);
my $timelocal = '';
eval {
    $timelocal = timelocal(@time);
};
ok(($timelocal == $time), qq{$^X @{[__FILE__]}});

__END__
