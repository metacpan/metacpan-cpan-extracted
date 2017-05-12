$::VERSION = $::VERSION = 0.01;
use 5.00503;
use strict;
use Test::Simply tests => 4;
use Stable::Module;

my $none = '';

$none = none {$_} 1,1,1,1;
ok((not $none), qq{none {\$_} 1,1,1,1 $^X @{[__FILE__]}});

$none = none {$_} 0,0,0,0;
ok($none, qq{none {\$_} 0,0,0,0 $^X @{[__FILE__]}});

$none = none {$_} 0,0,0,1;
ok((not $none), qq{none {\$_} 0,0,0,1 $^X @{[__FILE__]}});

$none = none {$_} 1,1,1,0;
ok((not $none), qq{none {\$_} 1,1,1,0 $^X @{[__FILE__]}});

__END__
