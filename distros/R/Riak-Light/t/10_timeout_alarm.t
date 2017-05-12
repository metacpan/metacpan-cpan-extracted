BEGIN {
    use Config;
    if ( $Config{osname} eq 'MSWin32' ) {
        require Test::More;
        Test::More::plan( skip_all =>
              'should not test Riak::Light::Timeout::Alarm under Win32' );
    }
}

use Test::More tests => 3;
use FindBin qw($Bin);
use lib "$Bin/tlib";
use TestTimeout qw(test_timeout test_normal_wait);
use Test::Exception;
use Test::MockModule;

subtest "test die under win32" => sub {

    use Riak::Light::Timeout::Alarm;
    my $module = Test::MockModule->new('Riak::Light::Timeout::Alarm');

    $module->mock( is_windows => 1 );

    throws_ok {
        Riak::Light::Timeout::Alarm->new( socket => undef );
    }
    qr/Alarm cannot interrupt blocking system calls in Win32/;

};

test_timeout('Riak::Light::Timeout::Alarm');
test_normal_wait('Riak::Light::Timeout::Alarm');
