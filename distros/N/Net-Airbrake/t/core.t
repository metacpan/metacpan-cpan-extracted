use strict;
use warnings;
use utf8;

use Test::More;
use Test::MockModule;
use Test::Exception;

use_ok 'Net::Airbrake';

my $airbrake = Net::Airbrake->new(
    api_key    => 'testapikey',
    project_id => 99999999,
    environment_name => 'test',
);
ok $airbrake, 'new()';

subtest 'notify()' => sub {
    my $mock = Test::MockModule->new('HTTP::Tiny');

    subtest 'success' => sub {
        $mock->mock(request => sub {
            +{
                success => 1,
                status  => 200,
                headers => { 'Content-Type' => 'application/json' },
                content => '{"id":"12345","url":"http://127.0.0.1/12345"}',
            };
        });
        eval { die 'エラー！！' };
        my $res = $airbrake->notify($@);
        ok $res;
        is $res->{id}, 12345;
        is $res->{url}, 'http://127.0.0.1/12345';
    };

    subtest 'fail on error response from server' => sub {
        $mock->mock(request => sub {
            +{
                success => 0,
                status  => 400,
                reason  => 'Bad request',
                content => 'Pending',
            };
        });
        eval { die 'エラー！！' };
        throws_ok { $airbrake->notify($@) } qr/Request failed to Airbrake:/;
    };
};

done_testing;
