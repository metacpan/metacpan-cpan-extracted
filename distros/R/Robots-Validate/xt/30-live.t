#!perl

use Test2::V0 -no_srand;
use Test2::Require::Internet -tcp => [ 'dns.google', 53 ];    # dns.google should map to 8.8.8.8 or 8.8.4.4

use Test::File::ShareDir -share => {
    -dist => {
        "Robots-Validate" => "share"
    }
};

use Net::DNS::Resolver;

use Robots::Validate;

use experimental qw( signatures );

my $resolver = Net::DNS::Resolver->new(
    nameservers => ['dns.google'],
    recurse     => 0,
    debug       => 0,
);

my $rv = Robots::Validate->new( resolver => $resolver );

subtest google => sub {

    run_tests(
        [

            {
                line => __LINE__,
                args => [ '66.249.66.80', 'Googlebot-Image/1.0' ],
                res  => [ 'google',       'googlebot' ],
            },
            {
                line => __LINE__,
                args => [
                    '66.249.66.80',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.71 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
                ],
                res => [ 'google', 'googlebot' ],
            },

            {
                line => __LINE__,
                args => [
                    '64.233.172.133', "Mozilla/5.0 (Windows NT 5.1; rv:11.0) Gecko Firefox/11.0 (via ggpht.com GoogleImageProxy)"
                ],
                res => [ 'google-user', 'googleimageproxy' ],
            },

            {
                line => __LINE__,
                args => [
                    '66.102.6.1',
"Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36 (compatible; Google-Read-Aloud; +https://support.google.com/webmasters/answer/1061943)"
                ],
                res => [ 'google-user', 'google-read-aloud' ],

            },

            {
                line => __LINE__,
                args => [
                    '34.80.50.80',
"Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.7922.173 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
                ],
                res => [ 'google', 'googlebot' ],
            },

            {
                line => __LINE__,
                args => [
                    '192.168.0.13',
"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
                ],
                res => undef,
            },

            {
                line => __LINE__,
                args => [
                    '192.168.0.13',
"Mozilla/5.0 (Linux; Android 13; SM-A725F Build/TP1A.220624.014; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/120.0.6099.144 Mobile Safari/537.36 GoogleLens/14.49.40.28.arm64"
                ],
                res => undef,
            },

            {
                line => __LINE__,
                args => [ '192.168.0.13', "WhatsApp/2.24.15.78 Android/14 Device/Google-Pixel_7" ],
                res  => undef,
            },

            {
                line => __LINE__,
                args => [ '162.248.224.200', "Googlebot-Image/1.0" ],
                res  => "",
            },

            {
                line => __LINE__,
                args => [
                    '35.187.252.153',
"Mozilla/5.0 (Windows NT 10.0; rv:127.16) Gecko/20100101 Firefox/127.16; compatible; Google-Extended/1.0; +http://www.google.com/bot.html"
                ],
                res => "",
            },

        ]

    );

};

subtest 'imessage' => sub {

    run_tests(
        [

            {
                line => __LINE__,
                args => [
                    '194.83.69.99',
"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.4 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.4 facebookexternalhit/1.1 Facebot Twitterbot/1.0"
                ],
                res => undef,
            },

            {
                line => __LINE__,
                args => [
                    '194.83.69.99', "Googlebot Facebot Twitterbot"
                ],
                res => "",
            },


        ]
    );

};

sub run_tests($tests) {

   for my $test ( $tests->@* ) {
        my @args = $test->{args}->@*;
        is $rv->validate(@args), $test->{res}, join( " ", sprintf( '[line %u]', $test->{line} ), @args );
    }


}

done_testing;
