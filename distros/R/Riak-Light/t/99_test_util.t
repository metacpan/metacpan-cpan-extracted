use Test::More tests => 2;
use Test::MockModule;
use Config;

subtest "is windows" => sub {
    require Riak::Light::Util;

    is( Riak::Light::Util::is_windows(), $Config{osname} eq 'MSWin32' );
};

subtest "is netbsd" => sub {
    require Riak::Light::Util;

    my $module = Test::MockModule->new('Riak::Light::Util');
    $module->mock( _is_netbsd => sub {0} );
    ok( !Riak::Light::Util::is_netbsd_6_32bits() );
};
