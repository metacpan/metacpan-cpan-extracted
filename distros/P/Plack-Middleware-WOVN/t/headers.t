use strict;
use warnings;
use Test::More;

use Cwd;
use File::Spec;
use lib File::Spec->catdir(getcwd(), 't', 'lib');
use TestHelper qw( get_env get_settings );

my $class = 'Plack::Middleware::WOVN::Headers';

use_ok($class);
use_ok('Plack::Middleware::WOVN::Lang');

my @lang;    # ( 'ar', 'da', 'de', ... 'zh-CHT' )
{
    no warnings 'once';
    @lang = keys %$Plack::Middleware::WOVN::Lang::LANG;
    @lang = sort @lang;
}

# INITIALIZE

subtest 'initialize' => sub {
    ok( $class->new( &get_env, &get_settings ) );
};

subtest 'initialize with simple url' => sub {
    my $h
        = $class->new( &get_env( { url => 'https://wovn.io' } ),
        &get_settings );
    is( $h->url, 'wovn.io/' );
};

subtest 'initialize with query language' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://wovn.io/?wovn=en' } ),
        &get_settings( { url_pattern => 'query' } )
    );
    is( $h->url, 'wovn.io/?' );
};

subtest 'initialize with query language without slash' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://wovn.io?wovn=en' } ),
        &get_settings( { url_pattern => 'query' } )
    );
    is( $h->url, 'wovn.io/?' );
};

subtest 'initialize with path language' => sub {
    my $h = $class->new( &get_env( { url => 'https://wovn.io/en' } ),
        &get_settings );
    is( $h->url, 'wovn.io/' );
};

subtest 'initialize with domain language' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://en.wovn.io/' } ),
        &get_settings( { url_pattern => 'subdomain' } )
    );
    is( $h->url, 'wovn.io/' );
};

subtest 'initialize with path language with query' => sub {
    my $h
        = $class->new(
        &get_env( { url => 'https://wovn.io/en/?wovn=zh-CHS' } ),
        &get_settings );
    is( $h->url, 'wovn.io/?wovn=zh-CHS' );
};

subtest 'initialize with domain language with query' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://en.wovn.io/?wovn=zh-CHS' } ),
        &get_settings( { url_pattern => 'subdomain' } )
    );
    is( $h->url, 'wovn.io/?wovn=zh-CHS' );
};

subtest 'initialize with path language with query without slash' => sub {
    my $h
        = $class->new(
        &get_env( { url => 'https://wovn.io/en?wovn=zh-CHS' } ),
        &get_settings );
    is( $h->url, 'wovn.io/?wovn=zh-CHS' );
};

subtest 'initialize with domain language with query without slash' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://en.wovn.io?wovn=zh-CHS' } ),
        &get_settings( { url_pattern => 'subdomain' } )
    );
    is( $h->url, 'wovn.io/?wovn=zh-CHS' );
};

# GET SETTINGS
# (none)

# PATH LANG: SUBDOMAIN

subtest 'path lang subdomain empty' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://.wovn.io' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+)\.'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang subdomain $l" => sub {
        my $h = $class->new(
            &get_env( { url => "https://$l.wovn.io" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang subdomain $l uppercase" => sub {
        my $h = $class->new(
            &get_env( { url => "https://$uc_l.wovn.io" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang subdomain $l losercase" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "https://$lc_l.wovn.io" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang subdomain empty with slash' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://.wovn.io/' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+)\.'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang subdomain $l with slash" => sub {
        my $h = $class->new(
            &get_env( { url => "https://$l.wovn.io/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang subdomain $l uppercase with slash" => sub {
        my $h = $class->new(
            &get_env( { url => "https://$uc_l.wovn.io/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang subdomain $l losercase with slash" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "https://$lc_l.wovn.io/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang subdomain empty with port' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://.wovn.io:1234' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+)\.'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang subdomain $l with port" => sub {
        my $h = $class->new(
            &get_env( { url => "https://$l.wovn.io:1234" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang subdomain $l uppercase with port" => sub {
        my $h = $class->new(
            &get_env( { url => "https://$uc_l.wovn.io:1234" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang subdomain $l losercase with port" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "https://$lc_l.wovn.io:1234" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang subdomain empty with slash with port' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://.wovn.io:1234/' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+)\.'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang subdomain $l with slash with port" => sub {
        my $h = $class->new(
            &get_env( { url => "https://$l.wovn.io:1234/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang subdomain $l uppercase with slash with port" => sub {
        my $h = $class->new(
            &get_env( { url => "https://$uc_l.wovn.io:1234/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang subdomain $l losercase with slash with port" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "https://$lc_l.wovn.io:1234/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang subdomain empty unsecure' => sub {
    my $h = $class->new(
        &get_env( { url => 'http://.wovn.io' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+)\.'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang subdomain $l unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://$l.wovn.io" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang subdomain $l uppercase unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://$uc_l.wovn.io" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang subdomain $l losercase unsecure" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "http://$lc_l.wovn.io" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang subdomain empty with slash unsecure' => sub {
    my $h = $class->new(
        &get_env( { url => 'http://.wovn.io/' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+)\.'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang subdomain $l with slash unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://$l.wovn.io/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang subdomain $l uppercase with slash unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://$uc_l.wovn.io/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang subdomain $l losercase with slash unsecure" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "http://$lc_l.wovn.io/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang subdomain empty with port unsecure' => sub {
    my $h = $class->new(
        &get_env( { url => 'http://.wovn.io:1234' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+)\.'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang subdomain $l with port unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://$l.wovn.io:1234" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang subdomain $l uppercase with port unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://$uc_l.wovn.io:1234" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang subdomain $l losercase with port unsecure" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "http://$lc_l.wovn.io:1234" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang subdomain empty with slash with port unsecure' => sub {
    my $h = $class->new(
        &get_env( { url => 'http://.wovn.io:1234/' } ),
        &get_settings(
            {   url_pattern     => 'subdomain',
                url_pattern_reg => '^(?<lang>[^.]+)\.'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang subdomain $l with slash with port unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://$l.wovn.io:1234/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest
        "path lang subdomain $l uppercase with slash with port unsecure" =>
        sub {
        my $h = $class->new(
            &get_env( { url => "http://$uc_l.wovn.io:1234/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
        };

    next if $l eq $lc_l;

    subtest
        "path lang subdomain $l losercase with slash with port unsecure" =>
        sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "http://$lc_l.wovn.io:1234/" } ),
            &get_settings(
                {   url_pattern     => 'subdomain',
                    url_pattern_reg => '^(?<lang>[^.]+).'
                }
            )
        );
        is( $h->path_lang, $l );
        };
}

# PATH LANG: QUERY

subtest 'path lang query empty' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://wovn.io?wovn=' } ),
        &get_settings(
            {   url_pattern     => 'query',
                url_pattern_reg => '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang query $l" => sub {
        my $h = $class->new(
            &get_env( { url => "https://wovn.io?wovn=$l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang query $l uppercase" => sub {
        my $h = $class->new(
            &get_env( { url => "https://wovn.io?wovn=$uc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang query $l lowercase" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "https://wovn.io?wovn=$lc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang query empty with slash' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://wovn.io/?wovn=' } ),
        &get_settings(
            {   url_pattern     => 'query',
                url_pattern_reg => '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang query $l with slash" => sub {
        my $h = $class->new(
            &get_env( { url => "https://wovn.io/?wovn=$l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang query $l uppercase with slash" => sub {
        my $h = $class->new(
            &get_env( { url => "https://wovn.io/?wovn=$uc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang query $l lowercase with slash" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "https://wovn.io/?wovn=$lc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang query empty with port' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://wovn.io:1234?wovn=' } ),
        &get_settings(
            {   url_pattern     => 'query',
                url_pattern_reg => '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang query $l with port" => sub {
        my $h = $class->new(
            &get_env( { url => "https://wovn.io:1234?wovn=$l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang query $l uppercase with port" => sub {
        my $h = $class->new(
            &get_env( { url => "https://wovn.io:1234?wovn=$uc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang query $l lowercase with port" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "https://wovn.io:1234?wovn=$lc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang query empty with slash with port' => sub {
    my $h = $class->new(
        &get_env( { url => 'https://wovn.io:1234/?wovn=' } ),
        &get_settings(
            {   url_pattern     => 'query',
                url_pattern_reg => '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang query $l with slash with port" => sub {
        my $h = $class->new(
            &get_env( { url => "https://wovn.io:1234/?wovn=$l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang query $l uppercase with slash with port" => sub {
        my $h = $class->new(
            &get_env( { url => "https://wovn.io:1234/?wovn=$uc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang query $l lowercase with slash with port" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "https://wovn.io:1234/?wovn=$lc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang query empty unsecure' => sub {
    my $h = $class->new(
        &get_env( { url => 'http://wovn.io?wovn=' } ),
        &get_settings(
            {   url_pattern     => 'query',
                url_pattern_reg => '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang query $l unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://wovn.io?wovn=$l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang query $l uppercase unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://wovn.io?wovn=$uc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang query $l lowercase unsecure" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "http://wovn.io?wovn=$lc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang query empty with slash unsecure' => sub {
    my $h = $class->new(
        &get_env( { url => 'http://wovn.io/?wovn=' } ),
        &get_settings(
            {   url_pattern     => 'query',
                url_pattern_reg => '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang query $l with slash unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://wovn.io/?wovn=$l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang query $l uppercase with slash unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://wovn.io/?wovn=$uc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang query $l lowercase with slash unsecure" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "http://wovn.io/?wovn=$lc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang query empty with port unsecure' => sub {
    my $h = $class->new(
        &get_env( { url => 'http://wovn.io:1234?wovn=' } ),
        &get_settings(
            {   url_pattern     => 'query',
                url_pattern_reg => '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang query $l with port unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://wovn.io:1234?wovn=$l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang query $l uppercase with port unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://wovn.io:1234?wovn=$uc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang query $l lowercase with port unsecure" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "http://wovn.io:1234?wovn=$lc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang query empty with slash with port unsecure' => sub {
    my $h = $class->new(
        &get_env( { url => 'http://wovn.io:1234/?wovn=' } ),
        &get_settings(
            {   url_pattern     => 'query',
                url_pattern_reg => '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
            }
        )
    );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang query $l with slash with port unsecure" => sub {
        my $h = $class->new(
            &get_env( { url => "http://wovn.io:1234/?wovn=$l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
    };

    subtest "path lang query $l uppercase with slash with port unsecure" =>
        sub {
        my $h = $class->new(
            &get_env( { url => "http://wovn.io:1234/?wovn=$uc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
        };

    next if $l eq $lc_l;

    subtest "path lang query $l lowercase with slash with port unsecure" =>
        sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new(
            &get_env( { url => "http://wovn.io:1234/?wovn=$lc_l" } ),
            &get_settings(
                {   url_pattern => 'query',
                    url_pattern_reg =>
                        '((\\?.*&)|\\?)wovn=(?<lang>[^&]+)(&|$)'
                }
            )
        );
        is( $h->path_lang, $l );
        };
}

# PATH LANG: PATH

subtest 'path lang path empty' => sub {
    my $h = $class->new( &get_env( { url => 'https://wovn.io' } ),
        &get_settings );
    is( $h->path_lang, '' );
};

subtest 'path lang path empty with slash' => sub {
    my $h = $class->new( &get_env( { url => 'https://wovn.io/' } ),
        &get_settings );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang path $l" => sub {
        my $h = $class->new( &get_env( { url => "https://wovn.io/$l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };

    subtest "path lang path $l uppercase" => sub {
        my $h = $class->new( &get_env( { url => "https://wovn.io/$uc_l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang path $l losercase" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new( &get_env( { url => "https://wovn.io/$lc_l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang path empty with port' => sub {
    my $h = $class->new( &get_env( { url => 'https://wovn.io:1234' } ),
        &get_settings );
    is( $h->path_lang, '' );
};

subtest 'path lang path empty with slash with port' => sub {
    my $h = $class->new( &get_env( { url => 'https://wovn.io:1234/' } ),
        &get_settings );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang path $l with port" => sub {
        my $h = $class->new( &get_env( { url => "https://wovn.io:1234/$l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };

    subtest "path lang path $l uppercase with port" => sub {
        my $h
            = $class->new(
            &get_env( { url => "https://wovn.io:1234/$uc_l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang path $l losercase with port" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h
            = $class->new(
            &get_env( { url => "https://wovn.io:1234/$lc_l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang path empty unsecure' => sub {
    my $h = $class->new( &get_env( { url => 'http://wovn.io' } ),
        &get_settings );
    is( $h->path_lang, '' );
};

subtest 'path lang path empty with slash unsecure' => sub {
    my $h = $class->new( &get_env( { url => 'http://wovn.io/' } ),
        &get_settings );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang path $l unsecure" => sub {
        my $h = $class->new( &get_env( { url => "http://wovn.io/$l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };

    subtest "path lang path $l uppercase unsecure" => sub {
        my $h = $class->new( &get_env( { url => "http://wovn.io/$uc_l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang path $l losercase unsecure" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h = $class->new( &get_env( { url => "http://wovn.io/$lc_l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };
}

subtest 'path lang path empty with port unsecure' => sub {
    my $h = $class->new( &get_env( { url => 'http://wovn.io:1234' } ),
        &get_settings );
    is( $h->path_lang, '' );
};

subtest 'path lang path empty with slash with port unsecure' => sub {
    my $h = $class->new( &get_env( { url => 'http://wovn.io:1234/' } ),
        &get_settings );
    is( $h->path_lang, '' );
};

for my $l (@lang) {
    my $lc_l = lc $l;
    my $uc_l = uc $l;

    subtest "path lang path $l with port unsecure" => sub {
        my $h = $class->new( &get_env( { url => "http://wovn.io:1234/$l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };

    subtest "path lang path $l uppercase with port unsecure" => sub {
        my $h
            = $class->new( &get_env( { url => "http://wovn.io:1234/$uc_l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };

    next if $l eq $lc_l;

    subtest "path lang path $l losercase with port unsecure" => sub {
        ok( $l eq 'zh-CHS' || $l eq 'zh-CHT' );

        my $h
            = $class->new( &get_env( { url => "http://wovn.io:1234/$lc_l" } ),
            &get_settings );
        is( $h->path_lang, $l );
    };
}

done_testing;

