$::VERSION = $::VERSION = 0.01;
use 5.00503;
use strict;
use Test::Simply tests => 1;
use Stable::Module;

my $minstr = '';
eval {
    $minstr = minstr('A'..'Z');
};
ok(($minstr eq 'A'), qq{$^X @{[__FILE__]}});

__END__
