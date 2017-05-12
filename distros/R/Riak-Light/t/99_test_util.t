use Test::More tests => 3;
use Test::MockModule;
use Config;

subtest "is windows" => sub {
    require Riak::Light::Util;

    is( Riak::Light::Util::is_windows(), $Config{osname} eq 'MSWin32' );
};

subtest "is netbsd" => sub {
    require Riak::Light::Util;

    is( Riak::Light::Util::is_netbsd(), $Config{osname} eq 'netbsd' );
};

subtest "is solaris" => sub {
    require Riak::Light::Util;

    is( Riak::Light::Util::is_solaris(), $Config{osname} eq 'solaris' );
};
