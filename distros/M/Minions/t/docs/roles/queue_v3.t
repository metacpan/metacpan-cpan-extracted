use strict;
use Test::Lib;
use Test::More;
use Test::Output;

use Minions
    bind => {
        'Example::Roles::Queue' => 'Example::Roles::Acme::Queue_v3',
    };
use Example::Roles::Queue;

my $q = Example::Roles::Queue->new;

$q->push(1);

my $item;
stderr_like(sub { $item = $q->pop }, qr'I have 1 element');
is($item, 1, 'pop');

done_testing();
