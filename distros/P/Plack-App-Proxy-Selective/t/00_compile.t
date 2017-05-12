use strict;
use warnings;

use Test::More;
use Path::Class;

BEGIN { use_ok 'Plack::App::Proxy::Selective' }


subtest 'initlialize selective with no filter' => sub {

    my $selective = Plack::App::Proxy::Selective->new();
    isa_ok($selective, 'Plack::Component', 'Plack::App::Proxy::Selective is an instance of Plack::Component');
    can_ok($selective, 'to_app');

    done_testing;
};


subtest 'initlialize selective with filter' => sub {

    my $googlefilter = +{
        'script' => '/js',
        '/css' => 'style',
    };

    my $yahoofilter = +{
        '/script' => 'js',
        'css' => '/style',
    };

    my $selective = Plack::App::Proxy::Selective->new(
        filter => +{
            'google.com' => $googlefilter,
            'www.yahoo.co.jp' => $yahoofilter,
        },
        base_dir => file(__FILE__)->dir,
    );
    my $filter = $selective->filter;

    is_deeply($filter->{'google.com'}, $googlefilter, 'google filter is same as original');
    is_deeply($filter->{'www.yahoo.co.jp'}, $yahoofilter, 'yahoo filter is same as original');

    done_testing;
};


done_testing;
