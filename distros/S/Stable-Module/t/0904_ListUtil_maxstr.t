$::VERSION = $::VERSION = 0.01;
use 5.00503;
use strict;
use Test::Simply tests => 1;
use Stable::Module;

my $maxstr = '';
eval {
    $maxstr = maxstr('A'..'Z');
};
ok(($maxstr eq 'Z'), qq{$^X @{[__FILE__]}});

__END__
