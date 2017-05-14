BEGIN {
    use Config;
    if ( $Config{osname} eq 'netbsd' ) {
        require Test::More;
        Test::More::plan( skip_all =>
              'should not test Riak::Light::Timeout::SetSockOpt under netbsd 6.0 (or superior) and longsize 4'
        );
    }
}

use Test::More tests => 5;
use FindBin qw($Bin);
use lib "$Bin/tlib";
use TestTimeout qw(test_timeout test_normal_wait);
use Test::MockModule;
use Test::MockObject;
use Test::Exception;

subtest "test die under netbsd 6" => sub {

    use Riak::Light::Timeout::SetSockOpt;
    my $module = Test::MockModule->new('Riak::Light::Timeout::SetSockOpt');

    $module->mock( is_netbsd_6_32bits => 1 );

    throws_ok {
        Riak::Light::Timeout::SetSockOpt->new( socket => undef );
    }
    qr/NetBSD no supported yet/;

};

subtest "test die if setsockopt fails for SO_RCVTIMEO" => sub {
    use Riak::Light::Timeout::SetSockOpt;

    my $mock = Test::MockObject->new();

    $! = 13;
    $mock->set_false('setsockopt');

    throws_ok {
        Riak::Light::Timeout::SetSockOpt->new( socket => $mock );
    }
    qr/setsockopt\(SO_RCVTIMEO\): $!/;
};

subtest "test die if setsockopt fail for SO_SNDTIMEO" => sub {
    use Riak::Light::Timeout::SetSockOpt;

    my $mock = Test::MockObject->new();

    $! = 13;
    $mock->set_series( 'setsockopt', 1, 0 );

    throws_ok {
        Riak::Light::Timeout::SetSockOpt->new( socket => $mock );
    }
    qr/setsockopt\(SO_SNDTIMEO\): $!/;
};

test_timeout('Riak::Light::Timeout::SetSockOpt');
test_normal_wait('Riak::Light::Timeout::SetSockOpt');
