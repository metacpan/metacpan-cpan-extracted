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
plan tests => 220;

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
    { dist => 'Baz', version => '0.4.0', abstract => 'Pg Baz' },
];

ok my $html = Template::Declare->show('home', $req, { cloud => $cloud, dists => $dists }),
    'Call the home template';

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
                    my $i = 0;
                    for my $dist (@{ $dists }) {
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
        $tx->is('count(./*)', 6, qq{Should have 6 elements below "head"});
        $tx->is(
            './title',
            'PGXN: PostgreSQL Extension Network',
            'Should have the page title',
        );
        $tx->is(
            './meta[@name="keywords"]/@content',
            'PostgreSQL, extensions, PGXN, PostgreSQL Extension Network',
            'Should have keywords meta element',
        );
        $tx->is(
            './meta[@name="description"]/@content',
            'Search all indexed extensions, distributions, users, and tags on the PostgreSQL Extension Network.',
            'Should have description meta element',
        );

        my $i = 0;
        my $v = PGXN::Site->version_string;
        for my $spec (
            [ html   => 'screen, projection, tv' ],
            [ layout => 'screen, projection, tv' ],
            [ print  => 'print'                  ],
        ) {
            ++$i;
            $tx->ok("./link[$i]", "Test styesheet $i", sub {
                $tx->is(
                    './@href',
                    "/ui/css/$spec->[0].css?$v",
                    "CSS $i should linke to $spec->[0].css"
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
                        [ '/recent/', 'Recent Releases',            'Recent'  ],
                        [ '/users/',  'PGXN Users',                 'Users'   ],
                        [ '/about/',  'About PGXN',                 'About'   ],
                        [ '/faq/',    'Frequently Asked Questions', 'FAQ'     ],
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
                $tx->is('count(./*)', 6, 'Should have 6elements below #floatLeft');
                $tx->is('./@class', 'floatLeft', 'Should be floatLeft');
                my $v = PGXN::Site->version_string;
                $tx->like('./text()', qr{^\Q$v\E\b}, qq{Text should contain "$v"});
                $tx->like('./text()', qr{\bcode\b}, 'Text should contain "code"');
                $tx->like('./text()', qr{\bdesign\b}, 'Text should contain "design"');
                $tx->like('./text()', qr{\blogo\b}, 'Text should contain "logo"');
                $tx->ok('./a[1]', 'Test first anchor', sub {
                    $tx->is('./@href', 'http://www.justatheory.com/', 'Should link to justatheory.com');
                    $tx->is('./@title', 'Go to Just a Theory', 'Should have link title');
                    $tx->is('./text()', 'theory', 'Should have text "theory"');
                });
                $tx->is('./span[1][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[2]', 'Test second anchor', sub {
                    $tx->is('./@href', 'http://fullahead.org/', 'Should link to fullahead.org');
                    $tx->is('./@title', 'Go to Fullahead', 'Should have link title');
                    $tx->is('./text()', 'Fullahead', 'Should have text "Fullahead"');
                });
                $tx->is('./span[2][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[3]', 'Test third anchor', sub {
                    $tx->is('./@href', 'http://www.strongrrl.com/', 'Should link to strongrrl.com');
                    $tx->is('./@title', 'Go to Strongrrl', 'Should have link title');
                    $tx->is('./text()', 'Strongrrl', 'Should have text "Strongrrl"');
                });
            }); # /span.floatLeft

                        # [ 'http://blog.pgxn.org/',    'Blog',       'Blog'    ],
                        # [ 'http://twitter.com/pgxn/', 'Twitter',    'Twitter' ],
            $tx->ok('./span[2]', 'Test the first span' => sub {
                $tx->is('./@class', 'floatRight', 'Should be floatRight');
                $tx->is('count(./*)', 13, 'Should have 11 elements below #floatRight');
                $tx->ok('./a[1]', 'Test blog anchor', sub {
                    $tx->is('./@href', 'http://blog.pgxn.org/', 'Should link to blog');
                    $tx->is('./@title', 'PGXN Blog', 'Should have link title');
                    $tx->is('./text()', 'Blog', 'Should have text "Blog"');
                });
                $tx->is('./span[1][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[2]', 'Test Twitter anchor', sub {
                    $tx->is('./@href', 'http://twitter.com/pgxn/', 'Should link to /mirroring/');
                    $tx->is('./@title', 'Follow PGXN on Twitter', 'Should have link title');
                    $tx->is('./text()', 'Twitter', 'Should have text "Twitter"');
                });
                $tx->is('./span[2][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[3]', 'Test PGXN Manager anchor', sub {
                    $tx->is('./@href', 'http://manager.pgxn.org/', 'Should link to manager');
                    $tx->is('./@title', 'Release it on PGXN', 'Should have link title');
                    $tx->is('./text()', 'Release It', 'Should have text "Release It"');
                });
                $tx->is('./span[3][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[4]', 'Test mirroring anchor', sub {
                    $tx->is('./@href', '/mirroring/', 'Should link to /mirroring/');
                    $tx->is('./@title', 'Mirroring', 'Should have link title');
                    $tx->is('./text()', 'Mirroring', 'Should have text "Mirroring"');
                });
                $tx->is('./span[4][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[5]', 'Test donors anchor', sub {
                    $tx->is('./@href', '/donors/', 'Should link to /donors/');
                    $tx->is('./@title', 'Donors', 'Should have link title');
                    $tx->is('./text()', 'Donors', 'Should have text "Donors"');
                });
                $tx->is('./span[5][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[6]', 'Test art anchor', sub {
                    $tx->is('./@href', '/art/', 'Should link to /art/');
                    $tx->is('./@title', 'Identity', 'Should have link title');
                    $tx->is('./text()', 'Identity', 'Should have text "Identity"');
                });
                $tx->is('./span[6][@class="grey"]', '|', 'Should have spacer span');
                $tx->ok('./a[7]', 'Test feedback anchor', sub {
                    $tx->is('./@href', '/feedback/', 'Should link to /feedback/');
                    $tx->is('./@title', 'Feedback', 'Should have link title');
                    $tx->is('./text()', 'Feedback', 'Should have text "Feedback"');
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
                $tx->is('./@class', 'width50', 'Class should be "width50"');
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
