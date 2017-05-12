use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package Foo::Backend;

    use strict;
    use parent 'Plack::Middleware::Throttle::Lite::Backend::Abstract';

    1;
};

{
    package Bar::Backend;

    use strict;
    use parent 'Plack::Middleware::Throttle::Lite::Backend::Abstract';

    sub reqs_done { 1 }
    sub increment { 1 }

    1;
};

my $foo = new_ok 'Foo::Backend';
my $bar = new_ok 'Bar::Backend';

my @be_methods = qw(reqs_max requester_id units settings expire_in ymdh cache_key);

throws_ok { $foo->reqs_done; }
    qr|method 'reqs_done' is not implemented|,      'foo throws on reqs_done()';

throws_ok { $foo->increment; }
    qr|method 'increment' is not implemented|,      'foo throws on increment()';

can_ok $foo, @be_methods;

lives_ok { $bar->reqs_done; }                       'bar lives on reqs_done()';
lives_ok { $bar->increment; }                       'bar lives on increment()';

can_ok $bar, @be_methods;

done_testing;
