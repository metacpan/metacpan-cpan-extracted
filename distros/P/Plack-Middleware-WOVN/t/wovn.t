use strict;
use warnings;
use utf8;
use Test::More;

use Cwd;
use File::Spec;
use lib File::Spec->catdir( getcwd(), 't', 'lib' );
use TestHelper qw( get_env get_settings generate_body generate_values );

my $class = 'Plack::Middleware::WOVN';

use_ok($class);
use_ok('Plack::Middleware::WOVN::Headers');

my $version = $Plack::Middleware::WOVN::VERSION;

subtest 'initialize' => sub {
    ok( $class->new );
};

subtest 'add lang code' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            'http://www.facebook.com', 'subdomain', 'zh-cht', $h
        ),
        'http://www.facebook.com'
    );
};

subtest 'add lang code relative slash href url with path' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://fr.favy.tips/topics/44' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );

    is( Plack::Middleware::WOVN::add_lang_code(
            '/topics/50', 'subdomain', 'fr', $h
        ),
        'http://fr.favy.tips/topics/50'
    );
};

subtest 'add lang code relative dot href url with path' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://fr.favy.tips/topics/44' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            './topics/50', 'subdomain', 'fr', $h
        ),
        'http://fr.favy.tips/topics/44/topics/50'
    );
};

subtest 'add lang code relative two dots href url with path' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://fr.favy.tips/topics/44' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            '../topics/50', 'subdomain', 'fr', $h
        ),
        'http://fr.favy.tips/topics/50'
    );
};

subtest 'add lang code trad chinese' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            'http://favy.tips/topics/31', 'subdomain', 'zh-cht', $h
        ),
        'http://zh-cht.favy.tips/topics/31'
    );
};

subtest 'add lang code trad chinese 2' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://zh-cht.favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            '/topics/31', 'subdomain', 'zh-cht', $h
        ),
        'http://zh-cht.favy.tips/topics/31'
    );
};

subtest 'add lang code trad chinese lang in link already' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://zh-cht.favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            'http://zh-cht.favy.tips/topics/31', 'subdomain',
            'zh-cht',                            $h
        ),
        'http://zh-cht.favy.tips/topics/31'
    );
};

subtest 'add lang code no protocol' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'https://zh-cht.google.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            '//google.com', 'subdomain', 'zh-cht', $h
        ),
        '//zh-cht.google.com'
    );
};

subtest 'add lang code no protocol 2' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'https://zh-cht.favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            '//google.com', 'subdomain', 'zh-cht', $h
        ),
        '//google.com'
    );
};

subtest 'add lang code invalid url' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            'http://www.facebook.com/sharer.php?u=http://favy.tips/topics/50&amp;amp;t=Gourmet Tofu World: Vegetarian-Friendly Japanese Food is Here!',
            'subdomain',
            'zh-cht',
            $h
        ),
        'http://www.facebook.com/sharer.php?u=http://favy.tips/topics/50&amp;amp;t=Gourmet Tofu World: Vegetarian-Friendly Japanese Food is Here!'
    );
};

subtest 'add lang code path only with slash' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            '/topics/31', 'subdomain', 'zh-cht', $h
        ),
        'http://zh-cht.favy.tips/topics/31'
    );
};

subtest 'add lang code path only no slash' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            'topics/31', 'subdomain', 'zh-cht', $h
        ),
        'http://zh-cht.favy.tips/topics/31'
    );
};

subtest 'add lang code path explicit page no slash' => sub {
    my $wovn = $class->new;
    my $h    = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            'topics/31.html', 'subdomain', 'zh-cht', $h
        ),
        'http://zh-cht.favy.tips/topics/31.html'
    );
};

subtest 'add lang code path explicit page with slash' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            '/topics/31.html', 'subdomain', 'zh-cht', $h
        ),
        'http://zh-cht.favy.tips/topics/31.html'
    );
};

subtest 'add lang code no protocol with path explicit page' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            '//www.google.com/topics/31.php',
            'subdomain', 'zh-cht', $h
        ),
        '//www.google.com/topics/31.php'
    );
};

subtest 'add lang code protocol with path explicit page' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            'http://www.google.com/topics/31.php', 'subdomain',
            'zh-cht',                              $h
        ),
        'http://www.google.com/topics/31.php'
    );
};

subtest 'add lang code relative path double period' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            '../topics/31', 'subdomain', 'zh-cht', $h
        ),
        'http://zh-cht.favy.tips/topics/31'
    );
};

subtest 'add lang code relative path single period' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            './topics/31', 'subdomain', 'zh-cht', $h
        ),
        'http://zh-cht.favy.tips/topics/31'
    );
};

subtest 'add lang code empty href' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            '', 'subdomain', 'zh-cht', $h
        ),
        ''
    );
};

subtest 'add lang code hash href' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://favy.tips' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    is( Plack::Middleware::WOVN::add_lang_code(
            '#', 'subdomain', 'zh-cht', $h
        ),
        '#'
    );
};

####

$class->new->prepare_app;

subtest 'switch lang' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://page.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    my $body   = &generate_body;
    my $values = &generate_values;
    my $url    = $h->url;
    my $swapped_body
        = Plack::Middleware::WOVN::switch_lang( $body, $values, $url, 'ja',
        $h );

    my $expected
        = qq(<!DOCTYPE html><html lang="ja"><head><script src="//j.wovn.io/1" async="true" data-wovnio="key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version"></script><link rel="alternate" hreflang="ja" href="http://ja.page.com/"/></head><body><h1>ベルベデアさんファンクラブ</h1><div><p>こんにちは</p></div> </body></html>);

    $swapped_body =~ s/>\s+</></gm;
    $expected =~ s/>\s+</></gm;

    is( $swapped_body, $expected );
};

subtest 'switch lang meta img alt tags' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://page.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    my $body   = &generate_body('meta_img_alt_tags');
    my $values = &generate_values;
    my $url    = $h->url;
    my $swapped_body
        = Plack::Middleware::WOVN::switch_lang( $body, $values, $url, 'ja',
        $h );

    my $expected = <<__HTML__;
<!DOCTYPE html><html lang="ja"><head><script src="//j.wovn.io/1" async="true" data-wovnio="key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version"> </script><meta content="こんにちは" name="description" />
 <meta content="こんにちは" name="title" />
 <meta content="こんにちは" property="og:title" />
 <meta content="こんにちは" property="og:description" />
 <meta content="こんにちは" property="twitter:title" />
 <meta content="こんにちは" property="twitter:description" /><link rel="alternate" hreflang="ja" href="http://ja.page.com/"/></head>
 <body><h1>ベルベデアさんファンクラブ</h1>
 <div><p>こんにちは</p></div>
 <img alt="こんにちは" src="http://example.com/photo.png" />
 </body></html>
__HTML__
    chomp $expected;

    $swapped_body =~ s/>\s+</></gm;
    $expected =~ s/>\s+</></gm;

    is( $swapped_body, $expected );
};

subtest 'switch lang wovn ignore' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://ignore-page.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    my $body   = &generate_body('ignore_parent');
    my $values = &generate_values;
    my $url    = $h->url;
    my $swapped_body
        = Plack::Middleware::WOVN::switch_lang( $body, $values, $url, 'ja',
        $h );

    my $expected
        = qq(<!DOCTYPE html><html lang="ja"><head><script src="//j.wovn.io/1" async="true" data-wovnio="key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version"> </script><link rel="alternate" hreflang="ja" href="http://ja.ignore-page.com/"/></head><body><h1>ベルベデアさんファンクラブ</h1>\n                <div wovn-ignore=""><p>Hello</p></div>\n              </body></html>);

    is( $swapped_body, $expected );
};

subtest 'switch lang wovn ignore everything' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://ignore-page.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    my $body   = &generate_body('ignore_everything');
    my $values = &generate_values;
    my $url    = $h->url;
    my $swapped_body
        = Plack::Middleware::WOVN::switch_lang( $body, $values, $url, 'ja',
        $h );

    my $expected
        = qq(<!DOCTYPE html><html lang="ja"><head><script src="//j.wovn.io/1" async="true" data-wovnio="key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version"> </script><link rel="alternate" hreflang="ja" href="http://ja.ignore-page.com/"/></head><body wovn-ignore=""><h1>Mr. Belvedere Fan Club</h1>\n                <div><p>Hello</p></div>\n              </body></html>);

    is( $swapped_body, $expected );
};

subtest 'switch lang wovn ignore empty' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://ignore-page.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    my $body   = &generate_body('empty');
    my $values = &generate_values;
    my $url    = $h->url;
    my $swapped_body
        = Plack::Middleware::WOVN::switch_lang( $body, $values, $url, 'ja',
        $h );

    my $expected
        = qq(<!DOCTYPE html><html lang="ja"><head><script src="//j.wovn.io/1" async="true" data-wovnio="key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version"> </script><link rel="alternate" hreflang="ja" href="http://ja.ignore-page.com/"/></head><body><h1>Mr.BelvedereFanClub</h1><div wovn-ignore=""><p>Hello</p></div></body></html>);

    is( $swapped_body, $expected );
};

subtest 'switch lang wovn ignore empty single quote' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://ignore-page.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    my $body   = &generate_body('empty_single_quote');
    my $values = &generate_values;
    my $url    = $h->url;
    my $swapped_body
        = Plack::Middleware::WOVN::switch_lang( $body, $values, $url, 'ja',
        $h );

    my $expected
        = qq(<!DOCTYPE html><html lang="ja"><head><script src="//j.wovn.io/1" async="true" data-wovnio="key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version"> </script><link rel="alternate" hreflang="ja" href="http://ja.ignore-page.com/"/></head><body><h1>Mr.BelvedereFanClub</h1><div wovn-ignore=""><p>Hello</p></div></body></html>);

    is( $swapped_body, $expected );
};

subtest 'switch lang wovn ignore empty double quote' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://ignore-page.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    my $body   = &generate_body('empty_double_quote');
    my $values = &generate_values;
    my $url    = $h->url;
    my $swapped_body
        = Plack::Middleware::WOVN::switch_lang( $body, $values, $url, 'ja',
        $h );

    my $expected
        = qq(<!DOCTYPE html><html lang="ja"><head><script src="//j.wovn.io/1" async="true" data-wovnio="key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version"> </script><link rel="alternate" hreflang="ja" href="http://ja.ignore-page.com/"/></head><body><h1>Mr.BelvedereFanClub</h1><div wovn-ignore=""><p>Hello</p></div></body></html>);

    is( $swapped_body, $expected );
};

subtest 'switch lang wovn ignore value single quote' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://ignore-page.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    my $body   = &generate_body('value_single_quote');
    my $values = &generate_values;
    my $url    = $h->url;
    my $swapped_body
        = Plack::Middleware::WOVN::switch_lang( $body, $values, $url, 'ja',
        $h );

    my $expected
        = qq(<!DOCTYPE html><html lang="ja"><head><script src="//j.wovn.io/1" async="true" data-wovnio="key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version"> </script><link rel="alternate" hreflang="ja" href="http://ja.ignore-page.com/"/></head><body><h1>Mr.BelvedereFanClub</h1><div wovn-ignore="value"><p>Hello</p></div></body></html>);

    is( $swapped_body, $expected );
};

subtest 'switch lang wovn ignore value double quote' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://ignore-page.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    my $body   = &generate_body('value_double_quote');
    my $values = &generate_values;
    my $url    = $h->url;
    my $swapped_body
        = Plack::Middleware::WOVN::switch_lang( $body, $values, $url, 'ja',
        $h );

    my $expected
        = qq(<!DOCTYPE html><html lang="ja"><head><script src="//j.wovn.io/1" async="true" data-wovnio="key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version"> </script><link rel="alternate" hreflang="ja" href="http://ja.ignore-page.com/"/></head><body><h1>Mr.BelvedereFanClub</h1><div wovn-ignore="value"><p>Hello</p></div></body></html>);

    is( $swapped_body, $expected );
};

subtest 'switch lang with script tag' => sub {
    my $h = Plack::Middleware::WOVN::Headers->new(
        &get_env( { url => 'http://ignore-page.com' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+).'
            }
        )
    );
    my $body
        = '<html><head><script src="//j.wovn.io/1" data-wovnio="key=2Wle3" async></script></head><body>Hello</body></html>';
    my $values = &generate_values;
    my $url    = $h->url;
    my $swapped_body
        = Plack::Middleware::WOVN::switch_lang( $body, $values, $url, 'ja',
        $h );

    my $expected
        = qq(<!DOCTYPE html><html lang="ja"><head><script src="//j.wovn.io/1" async="true" data-wovnio="key=&amp;backend=true&amp;currentLang=ja&amp;defaultLang=en&amp;urlPattern=path&amp;version=$version"> </script><link rel="alternate" hreflang="ja" href="http://ja.ignore-page.com/"/></head><body>こんにちは</body></html>);

    is( $swapped_body, $expected );
};

done_testing;

