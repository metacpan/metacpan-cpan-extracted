use strict;
use warnings;

use Test::More;
use Plack::App::FakeApache1;

my $pafa1 = Plack::App::FakeApache1->new;
isa_ok($pafa1, 'Plack::App::FakeApache1');

can_ok($pafa1,
    qw/
        call
        prepare_app
    /
);

my $faked_apache1 = Plack::App::FakeApache1->new(
    handler    => "Plack::App::FakeApache1::Handler",
    dir_config => {
        psgi_app        => './01-app/testapp.psgi',
        locations_from  => './01-app/testapp.conf',
    },
);

can_ok($faked_apache1,
    qw/
        call
        prepare_app
    /
);
is(
    $faked_apache1->handler,
    'Plack::App::FakeApache1::Handler',
    'handler value is correct',
);
is(
    $faked_apache1->dir_config->{psgi_app},
    './01-app/testapp.psgi',
    'dir_config/psgi_app value is correct',
);
is(
    $faked_apache1->dir_config->{locations_from},
    './01-app/testapp.conf',
    'dir_config/locations_from value is correct',
);

done_testing;
