use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Simply tests => 2;
use Stable::Module;

my $dirname = '';

eval {
    $dirname = dirname('/usr/local/bin/perl.pl');
};

ok(($dirname eq '/usr/local/bin'), qq{dirname('/usr/local/bin/perl.pl') $^X @{[__FILE__]}});

eval {
    $dirname = dirname('/usr/lo c al/bin/perl.pl');
};

ok(($dirname eq '/usr/lo c al/bin'), qq{dirname('/usr/lo c al/bin/perl.pl') $^X @{[__FILE__]}});

__END__
