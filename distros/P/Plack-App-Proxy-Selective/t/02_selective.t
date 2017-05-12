use strict;
use warnings;

use Test::Most;
use Path::Class;
use HTTP::Request;

use t::Util;

use Plack::App::Proxy::Selective;


subtest 'test with normal string filter' => sub {

    my $selective = Plack::App::Proxy::Selective->new(
        filter => +{
            'localhost' => +{
                'js' => '/js',
            }
        },
        base_dir => file(__FILE__)->dir,
    );

    dies_ok {
        $selective->call(+{});
    } 'selective requires env with HTTP_HOST and REQUEST_URI';

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'localhost', 'REQUEST_URI' => 'http://localhost/js/test.js' });
    } 'selective maps relative uri to local dir';


    test_app_dir(sub {
        my $cb = shift;
        my $res = $cb->(HTTP::Request->new(GET => 'js/happy_cpan_testers.js'));
    }, $selective);

    done_testing;
};


subtest 'test with regex filter' => sub {

    my $selective = Plack::App::Proxy::Selective->new(
        filter => +{
            'google.com' => +{
                '/css/js.*/' => '/style/',
                '/script/.*' => '/js/ext/',
            }
        },
        base_dir => file(__FILE__)->dir,
    );

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/script/test.js' });
    } 'selective maps ended-with-star uri to local dir';

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/script/hoge/test.js' });
    } 'selective maps ended-with-star uri to local dir recursively';



    done_testing;
};

done_testing;
