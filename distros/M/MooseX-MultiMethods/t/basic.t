use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('Foo') }

my $o = Foo->new;

lives_and(sub {
    is($o->foo(42), 'Int');
});

lives_and(sub {
    is($o->foo('foo'), 'Str');
});

dies_ok(sub {
    $o->foo([]);
});
