#!/usr/bin/env perl -w

use 5.10.0;
use utf8;
use Test::More;
use HTML::TagCloud;
use PGXN::Site;

BEGIN {
    for my $mod (qw(
        Test::XML
        Test::XPath
        HTTP::Request::Common
     )) {
        eval "use $mod;";
        plan skip_all => "$mod required for template testing" if $@;
    }
}

use PGXN::Site::Templates;
use Plack::Request;
use HTTP::Message::PSGI;

#plan 'no_plan';
plan tests => 242;

Template::Declare->init( dispatch_to => ['PGXN::Site::Templates'] );

ok my $req = Plack::Request->new(req_to_psgi(GET '/')),
    'Create a Plack request object';
my $mt = PGXN::Site::Locale->accept($req->env->{HTTP_ACCEPT_LANGUAGE});


my $cloud = HTML::TagCloud->new;
$cloud->add($_->{tag}, "/tag/$_->{tag}/", $_->{dist_count}) for (
    { tag => 'foo', dist_count => 2, },
    { tag => 'bar', dist_count => 4, },
    { tag => 'hi',  dist_count => 7, },
);

my $dists = [
    { dist => 'Foo', version => '1.2.1', abstract => 'Pg Foo' },
    { dist => 'Bar', version => '0.5.5', abstract => 'Pg Bar' },
    { dist => 'Foo', version => '1.2.0', abstract => 'Pg Foo' },
    { dist => 'Baz', version => '0.4.0', abstract => 'Pg Baz' },
    { dist => 'bar', version => '0.5.4', abstract => 'Pg Bar' },
    { dist => 'ick', version => '0.0.1', abstract => 'Pg Ick' },
    { dist => 'yoo', version => '0.0.1', abstract => 'Pg Yoo' },
    { dist => 'non', version => '0.0.1', abstract => 'Pg Non' },
];

ok my $html = Template::Declare->show('home', $req, {
    cloud => $cloud,
    dists => $dists,
    base_url => 'https://test.pgxn.org',
}), 'Call the home template';

is_well_formed_xml $html, 'The HTML should be well-formed';

test_wrapper($html, {
    title   => 'PGXN',
    content => sub {
        my $tx = shift;
        $tx->ok('./div[@id="homepage"]', 'Test homepage div', sub {
            $tx->is('count(./*)', 2, qq{Should have 2 elements below "homepage"});
            $tx->ok('./div[1]', 'Test first div' => sub {
                $tx->is('./@class', 'hsearch floatLeft', 'Should have class');
                $tx->is('count(./*)', 2, qq{Should have 2 elements below .hsearch});

                test_search_form($tx, 'homesearch', 'doc', '');

                $tx->ok('./div[@id="htmltagcloud"]', 'Test cloud' => sub {
                    # XXX Add cloud tests here.
                    $tx->is('count(./*)', 3, qq{Should have 3 elements below cloud});
                    $tx->is('count(./span)', 3, qq{And they should be spans});
                    $tx->ok('./span[1]', 'Test first tag span' => sub {
                        $tx->is('./@class', 'tagcloud1', '... Class is "tagcloud1"');
                        $tx->is('./a[@href="/tag/bar/"]', 'bar', 'Should link to tag "bar"');
                    });
                    $tx->ok('./span[2]', 'Test second tag span' => sub {
                        $tx->is('./@class', 'tagcloud0', '... Class is "tagcloud0"');
                        $tx->is('./a[@href="/tag/foo/"]', 'foo', 'Should link to tag "foo"');
                    });
                    $tx->ok('./span[3]', 'Test third tag span' => sub {
                        $tx->is('./@class', 'tagcloud3', '... Class is "tagcloud3"');
                        $tx->is('./a[@href="/tag/hi/"]', 'hi', 'Should link to tag "hi"');
                    });
                });
            });

            $tx->ok('./div[2]', 'Test second div' => sub {
                $tx->is(
                    './@class',
                    'hside floatLeft gradient',
                    'Should have class',
                );
                $tx->is('count(./*)', 4, 'Should have 4 sub-elements');
                $tx->is(
                    './p[1]',
                    $mt->maketext('pgxn_summary_paragraph'),
                    'First graph should be intro',
                );

                $tx->is('./h3', 'Recent Releases', qq{Header should be "Recent Releeases"});
                $tx->ok('./dl', 'Test release dl' => sub {
                    $tx->is('count(./dt)', 5, 'Should have 5 DT sub-elements');
                    my ($i, %seen) = (0);
                    for my $dist (@{ $dists }) {
                        next if $seen{ lc $dist->{dist} }++;
                        $i++;
                        $tx->ok("./dt[$i]", "Test dt $i" => sub {
                            $tx->ok('./a', "Test dt $i anchor" => sub {
                                $tx->is(
                                    './@href',
                                    lc "/dist/$dist->{dist}/$dist->{version}/",
                                    "href should be /dist/$dist->{dist}/$dist->{version}/",
                                );
                                $tx->is(
                                    './text()',
                                    "$dist->{dist} $dist->{version}",
                                    "text should be $dist->{dist} $dist->{version}",
                                );
                            });
                        });
                        $tx->is(
                            "./dd[$i]",
                            $dist->{abstract},
                            "dd $i should be correct"
                        );
                        last if $i == 5;
                    }
                });

                $tx->ok('./h6', 'Test h6 header' => sub {
                    $tx->is('./@class', 'floatRight', 'Should float right');
                    $tx->is('count(./*)', 1, 'Should have 1 sub-element');
                    $tx->ok('./a', 'Test anchor' => sub {
                        $tx->is(
                            './@href',
                            '/recent/',
                            'href should point to recent page.',
                        );
                        $tx->is(
                            './@title',
                            'See a longer list of recent releases.',
                            'Title should be correct',
                        );

                        $tx->is('./text()', 'More Releases →', 'Text should be "All Donors"');
                    });


                });

            });
        });
    },
});

sub test_wrapper {
    my $tx = Test::XPath->new( xml => shift, is_html => 1 );
    my $p = shift;

    # Some basic sanity-checking.
    $tx->is( 'count(/html)',      1, 'Should have 1 html element' );
    $tx->is( 'count(/html/head)', 1, 'Should have 1 head element' );
    $tx->is( 'count(/html/body)', 1, 'Should have 1 body element' );

    # Check the head element.
    $tx->ok('/html/head', 'Test head', sub {
        $tx->is('count(./*)', 26, qq{Should have 25 elements below "head"});
        # Title.
        $tx->is(
            './title',
            'PGXN: PostgreSQL Extension Network',
            'Should have the page title',
        );

        # Check the meta tags.
        my $v = PGXN::Site->version_string;
        for my $spec (
            ['name', 'viewport', 'width=device-width, initial-scale=1.0'],
            ['name', 'keywords', 'PostgreSQL, extensions, PGXN, PostgreSQL Extension Network'],
            ['name', 'description', 'Search all indexed extensions, distributions, users, and tags on the PostgreSQL Extension Network.'],
            ['name', 'twitter:card', 'summary'],
            ['name', 'twitter:site', '@pgxn'],
            ['name', 'twitter:title', 'PGXN: PostgreSQL Extension Network'],
            ['name', 'twitter:description', 'Search all indexed extensions, distributions, users, and tags on the PostgreSQL Extension Network.'],
            ['name', 'twitter:image', 'https://test.pgxn.org/ui/img/icon-512.png'],
            ['name', 'twitter:image:alt', 'PGXN gear logo'],
            ['name', 'generator', "PGXN::Site $v"],
            ['property', 'og:type', 'website'],
            ['property', 'og:url', 'https://test.pgxn.org/'],
            ['property', 'og:title', 'PGXN: PostgreSQL Extension Network'],
            ['property', 'og:site_name', 'PGXN: PostgreSQL Extension Network'],
            ['property', 'og:description', 'Search all indexed extensions, distributions, users, and tags on the PostgreSQL Extension Network.'],
            ['property', 'og:image', 'https://test.pgxn.org/ui/img/icon-512.png'],
        ) {
            $tx->is(
                qq{./meta[\@$spec->[0]="$spec->[1]"]/\@content}, $spec->[2],
                "Should have $spec->[1] meta element",
            );
        }

        # Check the stylesheets.
        my $i = 0;
        for my $spec (
            [ layout => 'screen, projection, tv' ],
            [ print  => 'print'                  ],
        ) {
            ++$i;
            $tx->ok("./link[$i]", "Test styesheet $i", sub {
                $tx->is(
                    './@href',
                    "/ui/css/$spec->[0].css?$v",
                    "CSS $i should link to $spec->[0].css"
                );
                $tx->is(
                    './@rel',
                    'stylesheet',
                    "$spec->[0] should be a stylesheet"
                );
                $tx->is(
                    './@type',
                    'text/css',
                    "$spec->[0] should be text/css"
                );
                $tx->is(
                    './@media',
                    $spec->[1],
                    "$spec->[0] should be for $spec->[1]"
                );
            });
        }

        # Check the SVG icon.
        ++$i;
        $tx->ok("./link[$i]", "Test SVG icon", sub {
            $tx->is(
                './@rel', 'icon',
                "SVG Icon should be an icon",
            );
            $tx->is(
                './@href', "/ui/img/icon.svg",
                "SVG Icon link to icon.svg",
            );
        });

        # Check the ICO icon.
        ++$i;
        $tx->ok("./link[$i]", "Test ICO icon", sub {
            $tx->is(
                './@rel', 'icon',
                "ICO Icon should be an icon",
            );
            $tx->is(
                './@href', "/ui/img/icon.ico",
                "ICO Icon link to icon.ico",
            );
        });

        # Check the favicons.
        for my $size (qw(256 32)) {
            ++$i;
            $tx->ok("./link[$i]", "Test $size icon", sub {
                $tx->is(
                    './@rel', 'icon',
                    qq{Icon $size should be an "icon"},
                );
                $tx->is(
                    './@href', "/ui/img/icon-$size.png",
                    "Icon $size link to icon-$size.png",
                );
                $tx->is(
                    './@type', 'image/png',
                    "Icon $size type should be img/png",
                );
                $tx->is(
                    './@sizes', "${size}x${size}",
                    "Icon $size type should be sized",
                );
            });
        }

        # Check the other icon and UI stuff.
        for my $spec (
            {
                rel   => 'apple-touch-icon',
                href  => '/ui/img/icon-180.png',
                sizes => '180x180',
            },
            {
                rel  => 'manifest',
                href => '/ui/manifest.json',
            },
            {
                rel  => 'me',
                href => 'https://botsin.space/@pgxn',
            },
        ) {
            ++$i;
            $tx->ok("./link[$i]", "Test link $i", sub {
                while (my ($k, $v) = each %{ $spec }) {
                    $tx->is("./\@$k", $v, "Link $i rel should be $v");
                }
            });
            
        }
    }); # /head

    # Test the body.
    $tx->is('count(/html/body/*)', 2, 'Should have two elements below body');

    # Check the header section.
    $tx->ok('/html/body/div[@id="all"]/div[@id="header"]', 'Test header', sub {
        $tx->ok('./div[@id="title"]', 'Test title', sub {
            $tx->is('./h1', 'PGXN', 'Should have h1');
            $tx->is('./h2', 'PostgreSQL Extension Network', 'Should have h2');
        });
        $tx->ok('./a[@rel="home"]', 'Test home', sub {
            $tx->is('./@href', '/', 'href should be /');
            $tx->is('count(./*)', 2, 'Should have two sub-elements');
            $tx->is('count(./img)', 2, 'And both should be images');
            $tx->ok('./img[1]', 'Test first image', sub {
                $tx->is('./@src', '/ui/img/gear.png', '... Src should be gear.png');
                $tx->is('./@alt', 'PGXN Gear', '... Alt should be "PGXN Gear"');
            });
            $tx->ok('./img[2]', 'Test second image', sub {
                $tx->is('./@src', '/ui/img/pgxn.png', '... Src should be pgxn.png');
                $tx->is(
                    './@alt',
                    'PostgreSQL Extension Network',
                    '... Alt should be "PostgreSQL Extension Network"'
                );
                $tx->is('./@class', 'right', '... Class should be "right"');
            });
        });
    }); # /div#header

    # Test the content section.
    $tx->ok('/html/body/div[@id="all"]/div[@id="content"]', 'Test content', sub {
        $tx->is('count(./*)', 2, qq{Should have 2 elements below #content});
        $tx->is('count(./div)', 2, qq{Both should be divs});
        $tx->ok('./div[@id="mainMenu"]', 'Test main menu' => sub {
            if ($p->{crumb}) {
                $tx->is('count(./*)', 2, 'Should have two subelements below #mainMenu');
                $tx->is('count(./ul)', 2, qq{Both should be uls});
                $tx->ok('./ul[1]', 'Test first ul' => sub {
                    # XXX Add crumb tests.
                });
            } else {
                $tx->is('count(./*)', 1, 'Should have one subelement below #mainMenu');
                $tx->is('count(./ul)', 1, qq{It should be a ul});
                $tx->ok('./ul[@class="floatRight"]', 'Test floatRight ul' => sub {
                    my $i = 0;
                    for my $spec (
                        [ '/users/',  'PGXN Users',      'Users'  ],
                        [ '/tags/',   'Release Tags',    'Tags'   ],
                        [ '/recent/', 'Recent Releases', 'Recent' ],
                    ) {
                        $i++;
                        $tx->ok("./li[$i]", "Test li $i", sub {
                            $tx->is('count(./*)', 1, '... Should have one subelement');
                            $tx->is('./a/@href', $spec->[0], "... Should point to $spec->[0]");
                            $tx->is('./a/@title', $spec->[1], qq{... Should have title "$spec->[1]"});
                            $tx->is('./a', $spec->[2], qq{... Should have text "$spec->[2]"});
                        });
                    }
                })
            }
        }); # /div/#mainMenu

        # Content of the page goes here.
        $p->{content}->($tx);

    }); # /div#content

    # Test footer.
    $tx->ok('/html/body/div[@id="footer"]', 'Test footer', sub {
        $tx->is('count(./*)', 1, qq{Should have 1 element below #footer});
        $tx->ok('./div[@id="width"]', 'Test width' => sub {
            $tx->is('count(./*)', 2, 'Should have 2 elements below #width');
            $tx->is('count(./span)', 2, 'Both should be spans');
            $tx->ok('./span[1]', 'Test the first span' => sub {
                $tx->is('count(./*)', 5, 'Should have 5 elements below #floatLeft');
                $tx->is('./@class', 'floatLeft', 'Should be floatLeft');
                my $v = PGXN::Site->version_string;
                $tx->ok('./a[1]', 'Test first anchor', sub {
                    $tx->is('./@href', 'https://blog.pgxn.org/', 'Should link to blog.pgxn.org');
                    $tx->is('./@title', $mt->maketext('PGXN Blog'), 'Should have link title');
                    $tx->is('./text()', $mt->maketext('Blog'), 'Should have text "Blog"');
                });
                $tx->is('./span[1][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[2]', 'Test second anchor', sub {
                    $tx->is('./@href', 'https://botsin.space/@pgxn', 'Should link to Mastodon');
                    $tx->is('./@title', $mt->maketext('Follow PGXN on Mastodon'), 'Should have link title');
                    $tx->is('./@rel', 'me', 'Should have rel=me in Mastodon link');
                    $tx->is('./text()', $mt->maketext('Mastodon'), 'Should have text "Blog"');
                });
                $tx->is('./span[2][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[3]', 'Test third anchor', sub {
                    $tx->is('./@href', 'https://manager.pgxn.org/', 'Should link to manage.pgxn.org');
                    $tx->is('./@title', $mt->maketext('Release it on PGXN'), 'Should have link title');
                    $tx->is('./text()', $mt->maketext('Release It'), 'Should have text "Blog"');
                });
            }); # /span.floatLeft

            $tx->ok('./span[2]', 'Test the second span' => sub {
                $tx->is('./@class', 'floatRight', 'Should be floatRight');
                $tx->is('count(./*)', 7, 'Should have 7 elements below #floatRight');
                $tx->ok('./a[1]', 'Test about anchor', sub {
                    $tx->is('./@href', '/about/', 'Should link to about');
                    $tx->is('./@title', $mt->maketext('About PGXN'), 'Should have link title');
                    $tx->is('./text()', $mt->maketext('About'), 'Should have text "About"');
                });
                $tx->is('./span[1][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[2]', 'Test FAQ anchor', sub {
                    $tx->is('./@href', '/faq/', 'Should link to about');
                    $tx->is('./@title', $mt->maketext('Frequently Asked Questions'), 'Should have link title');
                    $tx->is('./text()', $mt->maketext('FAQ'), 'Should have text "FAQ"');
                });
               $tx->is('./span[2][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[3]', 'Test mirroring anchor', sub {
                    $tx->is('./@href', '/mirroring/', 'Should link to /mirroring/');
                    $tx->is('./@title', $mt->maketext('Mirroring'), 'Should have link title');
                    $tx->is('./text()', $mt->maketext('Mirroring'), 'Should have text "Mirroring"');
                });
                $tx->is('./span[3][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[4]', 'Test feedback anchor', sub {
                    $tx->is('./@href', '/feedback/', 'Should link to /feedback/');
                    $tx->is('./@title', $mt->maketext('Feedback'), 'Should have link title');
                    $tx->is('./text()', $mt->maketext('Feedback'), 'Should have text "Feedback"');
                });
            }) # /span.floatRight

        }); # /div#width

    }); # /div#footer
}

sub test_search_form {
    my ($tx, $id, $in, $q) = @_;
    $tx->ok(qq{./form[\@id="$id"]}, "Test form#$id" => sub {
        $tx->is('./@action', '/search', 'Action should be /search');
        $tx->is('./@enctype', 'application/x-www-form-urlencoded', 'Should have enctype');
        $tx->is('./@method', 'get', 'Should be method=get');

        $tx->is('count(./*)', 2, 'Should have 2 elements below form');
        $tx->is('count(./fieldset)', 2, 'Boty should be fieldsets');

        $tx->ok('./fieldset[1]', 'Test first fieldset' => sub {
            $tx->is('./@class', 'query', 'Class should be "query"');
            $tx->is('count(./*)', 1, 'Should have 1 sub-element');
            $tx->ok('./input[@type="text"]', 'Test query input' => sub {
                $tx->is('./@name', 'q', 'Name should be "q"');
                $tx->is('./@value', $q, qq{Value should be "$q"});
                $tx->is(
                    './@autofocus',
                    $id eq 'homesearch' ? 'autofocus' : undef,
                    'Should have autofocus',
                )
            });
        });

        $tx->ok('./fieldset[2]', 'Test second fieldset' => sub {
            $tx->is('./@class', 'submitin', 'Class should be "submitin"');
            $tx->is('count(./*)', 3, 'Should have 3 sub-elements');

            $tx->ok('./label', 'Test label' => sub {
                $tx->is('./@id', 'inlabel', 'ID should be "inlabel"');
                $tx->is('./@for', 'searchin', 'For should be "searchin"');
                $tx->is('./text()', 'in', 'Text should be "in"');
            });

            $tx->ok('./select[@id="searchin"]', 'Test select#searchin' => sub {
                $tx->is('./@name', 'in', 'Name should be "in"');
                $tx->is('count(./*)', 5, 'Should have 5 sub-elements');
                $tx->is('count(./option)', 5, 'All should be options');

                my $i = 0;
                for my $spec (
                    [ docs       => 'Documentation' ],
                    [ extensions => 'Extensions'    ],
                    [ dists      => 'Distributions' ],
                    [ users      => 'Users'         ],
                    [ tags       => 'Tags'          ],
                ) {
                    ++$i;
                    $tx->ok("./option[$i]", "Test option $i" => sub {
                        $tx->is('./@value', $spec->[0], qq{Value should be "$spec->[0]"});
                        $tx->is('./@selected', 'selected', 'should be selected')
                            if $spec eq $in;
                        $tx->is('./text()', $spec->[1], qq{Should have text "$spec->[1]"});
                    });
                }
            });

            $tx->ok('./input[@type="submit"]', 'Test submit input' => sub {
                $tx->is('./@class', 'button', 'Class should be "button"');
                $tx->is('./@value', 'PGXN Search', qq{Value should be "PGXN Search"});
            });
        });
    });
}
