package TestHelper;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw( get_settings get_env generate_body generate_values );

use URI;

use Plack::Middleware::WOVN;
my $version = $Plack::Middleware::WOVN::VERSION;

sub get_settings {
    my $options = shift || {};
    my $settings = {
        user_token      => 'OHYx9',
        url_pattern     => 'path',
        url_pattern_reg => "/(?<lang>[^/.?]+)",
        query           => [],
        api_url         => 'https://api.wovn.io/v0/values',
        default_lang    => 'en',
        supported_langs => [],
        secret_key      => '',
    };
    +{ %$settings, %$options };
}

sub get_env {
    my $options = shift || {};
    my $env = {
        'psgi.url_scheme' => 'http',
        HTTP_HOST         => 'wovn.io',
        REQUEST_URI       => '/dashboard?param=val&hey=you',
        SERVER_NAME       => 'wovn.io',
        HTTP_COOKIE =>
            'olfsk=olfsk021093478426337242; hblid=KB8AAMzxzu2DSxnB4X7BJ26rBGVeF0yJ; optimizelyEndUserId=oeu1426233718869r0.5398541854228824; __zlcmid=UFeZqrVo6Mv3Yl; wovn_selected_lang=en; optimizelySegments=%7B%7D; optimizelyBuckets=%7B%7D; _equalizer_session=eDFwM3M2QUZJZFhoby9JZlArckcvSUJwNFRINXhUeUxtNnltQXZhV0tqdGhZQjJMZ01URnZTK05ydFVWYmM3U0dtMVN0M0Z0UnNDVG8vdUNDTUtPc21jY0FHREgrZ05CUnBTb0hyUlkvYlBWQVhQR3RZdnhjMWsrRW5rOVp1Z3V3bkgyd3NpSlRZQWU1dlZvNmM1THp6aUZVeE83Y1pWWENRNTBUVFIrV05WeTdDMlFlem1tUzdxaEtndFZBd2dtUjU2ak5EUmJPa3RWWmMyT1pSVWdMTm8zOVZhUWhHdGQ3L1c5bm91RmNSdFRrcC90Tml4N2t3ZWlBaDRya2lLT1I0S0J2TURhUWl6Uk5rOTQ4Y1MwM3VKYnlLMUYraEt5clhRdFd1eGdEWXdZd3pFbWQvdE9vQndhdDVQbXNLcHBURm9CbnZKenU2YnNXRFdqRVl0MVV3bmRyYjhvMDExcGtUVU9tK1lqUGswM3p6M05tbVRnTjE3TUl5cEdpTTZ4a2gray8xK0FvTC9wUDVka1JSeE5GM1prZmRjWDdyVzRhWW5uS2Mxc1BxOEVVTTZFS3N5bTlVN2p5eE5YSjNZWGI2UHd3Vzc0bDM5QjIwL0l5Mm85NmQyWFAwdVQ3ZzJYYk1QOHY2NVJpY2c9LS1KNU96eHVycVJxSDJMbEc4Rm9KVXpBPT0%3D--17e47555d692fb9cde20ef78a09a5eabbf805bb3; mp_a0452663eb7abb7dfa9c94007ebb0090_mixpanel=%7B%22distinct_id%22%3A%20%2253ed9ffa4a65662e37000000%22%2C%22%24initial_referrer%22%3A%20%22http%3A%2F%2Fp.dev-wovn.io%3A8080%2Fhttp%3A%2F%2Fdev-wovn.io%3A3000%22%2C%22%24initial_referring_domain%22%3A%20%22p.dev-wovn.io%3A8080%22%2C%22__mps%22%3A%20%7B%7D%2C%22__mpso%22%3A%20%7B%7D%2C%22__mpa%22%3A%20%7B%7D%2C%22__mpu%22%3A%20%7B%7D%2C%22__mpap%22%3A%20%5B%5D%7D',
        HTTP_ACCEPT_LANGUAGE => 'ja,en-US;q=0.8,en;q=0.6',
        QUERY_STRING         => 'param=val&hey=you',
        ORIGINAL_FULLPATH    => '/dashboard?param=val&hey=you',
        REQUEST_PATH         => '/dashboard',
        PATH_INFO            => '/dashboard',
    };

    if ( $options->{url} ) {
        my $url = URI->new( $options->{url} );

        $env->{'psgi.url_scheme'} = $url->scheme;
        $env->{HTTP_HOST} = $url->host;
        if (   ( $url->scheme eq 'http' && $url->port != 80 )
            || ( $url->scheme eq 'https' && $url->port != 443 ) )
        {
            $env->{HTTP_HOST} .= ':' . $url->port;
        }
        $env->{SERVER_NAME} = $url->host;

        my $path_query = $url->path_query || '/';
        if ( $path_query !~ /^\// ) {
            $path_query = '/' . $path_query;
        }
        $env->{REQUEST_URI}       = $path_query;
        $env->{ORIGINAL_FULLPATH} = $path_query;

        $env->{QUERY_STRING} = $url->query;
        $env->{REQUEST_PATH} = $url->path;
        $env->{PATH_INFO}    = $url->path;
    }

    +{ %$env, %$options };
}

sub generate_body {
    my $param = shift;
    $param = '' unless defined $param;

    my $body;
    if ( $param eq 'ignore_parent' ) {
        $body = qq(<html><body><h1>Mr. Belvedere Fan Club</h1>
                <div wovn-ignore><p>Hello</p></div>
              </body></html>);
    }
    elsif ( $param eq 'ignore_everything' ) {
        $body = qq(<html><body wovn-ignore><h1>Mr. Belvedere Fan Club</h1>
                <div><p>Hello</p></div>
              </body></html>);
    }
    elsif ( $param eq 'ignore_parent_translated_in_japanese' ) {
        $body = qq(<html lang=\"ja\">
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">
<script src=\"//j.wovn.io/1\" async=\"true\" data-wovnio=\"key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version\"> </script><link rel=\"alternate\" hreflang=\"ja\" href=\"http://ja.ignore-page.com/\">
</head>
<body>
<h1>ベルベデアさんファンクラブ</h1>
                <div wovn-ignore=\"\"><p>Hello</p></div>
              </body>
</html>
);
    }
    elsif ( $param eq 'translated_in_japanese' ) {
        $body = qq(<html lang=\"ja\">
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">
<script src=\"//j.wovn.io/1\" async=\"true\" data-wovnio=\"key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version\"> </script><link rel=\"alternate\" hreflang=\"ja\" href=\"http://ja.page.com/\">
</head>
<body>
<h1>ベルベデアさんファンクラブ</h1>
                <div><p>こんにちは</p></div>
              </body>
</html>
);
    }
    elsif ( $param eq 'ignore_everything_translated' ) {
        $body = qq(<html lang=\"ja\">
<head>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">
<script src=\"//j.wovn.io/1\" async=\"true\" data-wovnio=\"key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version\"> </script><link rel=\"alternate\" hreflang=\"ja\" href=\"http://ja.ignore-page.com/\">
</head>
<body wovn-ignore=\"\">
<h1>Mr. Belvedere Fan Club</h1>
                <div><p>Hello</p></div>
              </body>
</html>
);
    }
    elsif ( $param eq 'empty' ) {
        $body
            = "<html><body><h1>Mr.BelvedereFanClub</h1><div wovn-ignore><p>Hello</p></div></body></html>";
    }
    elsif ( $param eq 'empty_single_quote' ) {
        $body
            = "<html><body><h1>Mr.BelvedereFanClub</h1><div wovn-ignore=''><p>Hello</p></div></body></html>";
    }
    elsif ( $param eq 'empty_double_quote' ) {
        $body
            = qq(<html><body><h1>Mr.BelvedereFanClub</h1><div wovn-ignore=""><p>Hello</p></div></body></html>);
    }
    elsif ( $param eq 'value_single_quote' ) {
        $body
            = "<html><body><h1>Mr.BelvedereFanClub</h1><div wovn-ignore='value'><p>Hello</p></div></body></html>";
    }
    elsif ( $param eq 'value_double_quote' ) {
        $body
            = "<html><body><h1>Mr.BelvedereFanClub</h1><div wovn-ignore=\"value\"><p>Hello</p></div></body></html>";
    }
    elsif ( $param eq 'empty_translated' ) {
        $body
            = "<html lang=\"ja\">\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<script src=\"//j.wovn.io/1\" async=\"true\" data-wovnio=\"key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version\"> </script><link rel=\"alternate\" hreflang=\"ja\" href=\"http://ja.ignore-page.com/\">\n</head>\n<body>\n<h1>Mr.BelvedereFanClub</h1>\n<div wovn-ignore=\"\"><p>Hello</p></div>\n</body>\n</html>\n";
    }
    elsif ( $param eq 'empty_single_quote_translated' ) {
        $body
            = "<html lang=\"ja\">\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<script src=\"//j.wovn.io/1\" async=\"true\" data-wovnio=\"key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version\"> </script><link rel=\"alternate\" hreflang=\"ja\" href=\"http://ja.ignore-page.com/\">\n</head>\n<body>\n<h1>Mr.BelvedereFanClub</h1>\n<div wovn-ignore=\"\"><p>Hello</p></div>\n</body>\n</html>\n";
    }
    elsif ( $param eq 'empty_double_quote_translated' ) {
        $body
            = "<html lang=\"ja\">\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<script src=\"//j.wovn.io/1\" async=\"true\" data-wovnio=\"key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version\"> </script><link rel=\"alternate\" hreflang=\"ja\" href=\"http://ja.ignore-page.com/\">\n</head>\n<body>\n<h1>Mr.BelvedereFanClub</h1>\n<div wovn-ignore=\"\"><p>Hello</p></div>\n</body>\n</html>\n";
    }
    elsif ( $param eq 'value_single_quote_translated' ) {
        $body
            = "<html lang=\"ja\">\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<script src=\"//j.wovn.io/1\" async=\"true\" data-wovnio=\"key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version\"> </script><link rel=\"alternate\" hreflang=\"ja\" href=\"http://ja.ignore-page.com/\">\n</head>\n<body>\n<h1>Mr.BelvedereFanClub</h1>\n<div wovn-ignore=\"value\"><p>Hello</p></div>\n</body>\n</html>\n";
    }
    elsif ( $param eq 'value_double_quote_translated' ) {
        $body
            = "<html lang=\"ja\">\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<script src=\"//j.wovn.io/1\" async=\"true\" data-wovnio=\"key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version\"> </script><link rel=\"alternate\" hreflang=\"ja\" href=\"http://ja.ignore-page.com/\">\n</head>\n<body>\n<h1>Mr.BelvedereFanClub</h1>\n<div wovn-ignore=\"value\"><p>Hello</p></div>\n</body>\n</html>\n";
    }
    elsif ( $param eq 'meta_img_alt_tags_translated' ) {
        $body
            = "<html lang=\"ja\">\n<head>\n<script src=\"//j.wovn.io/1\" async=\"true\" data-wovnio=\"key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version\"> </script><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<meta name=\"description\" content=\"こんにちは\">\n<meta name=\"title\" content=\"こんにちは\">\n<meta property=\"og:title\" content=\"こんにちは\">\n<meta property=\"og:description\" content=\"こんにちは\">\n<meta property=\"twitter:title\" content=\"こんにちは\">\n<meta property=\"twitter:description\" content=\"こんにちは\">\n<link rel=\"alternate\" hreflang=\"ja\" href=\"http://ja.page.com/\">\n</head>\n<body>\n<h1>ベルベデアさんファンクラブ</h1>\n<div><p>こんにちは</p></div>\n<img src=\"http://example.com/photo.png\" alt=\"こんにちは\">\n</body>\n</html>\n";
    }
    elsif ( $param eq 'meta_img_alt_tags' ) {
        $body
            = qq(<html><head><meta name =\"description\" content=\"Hello\">\n<meta name=\"title\" content=\"Hello\">\n<meta property=\"og:title\" content=\"Hello\">\n<meta property=\"og:description\" content=\"Hello\">\n<meta property=\"twitter:title\" content=\"Hello\">\n<meta property=\"twitter:description\" content=\"Hello\"></head>
<body><h1>Mr. Belvedere Fan Club</h1>
<div><p>Hello</p></div>
<img src=\"http://example.com/photo.png\" alt=\"Hello\">
</body></html>);
    }
    else {
        $body = qq(<html><body><h1>Mr. Belvedere Fan Club</h1>
                <div><p>Hello</p></div>
              </body></html>);
    }
    $body;
}

sub generate_values {
    my $values = {
        text_vals => {
            Hello => { ja => [ { data => 'こんにちは' } ] },
            'Mr. Belvedere Fan Club' => {
                ja =>
                    [ { data => 'ベルベデアさんファンクラブ' } ]
            },
        },
    };
}

1;

