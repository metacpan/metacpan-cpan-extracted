#!/usr/bin/perl -w

use strict;
use Test::More tests => 183;
#use Test::More 'no_plan';
use File::Spec::Functions qw(tmpdir catdir catfile rel2abs);
use File::Path qw(remove_tree);
use Test::File;
use Test::XPath;
use File::Copy qw(cp);
use utf8;

my $CLASS;
BEGIN {
    $CLASS = 'Pod::Site';
    use_ok $CLASS or die;
}

my $mod_root = catdir qw(t lib);
my $mod_dir  = rel2abs $mod_root;
my $bin_root = catdir qw(t bin);
my $bin_dir  = rel2abs $bin_root;
my $tmpdir   = catdir tmpdir, "$$-pod-site-test";
my $doc_root = catdir $tmpdir, 'doc_root';
my $base_uri = '/docs/';
my $suffix   = '';
my $newline  = "\n";

if ($^O eq 'MSWin32') {
    $suffix   = '.bat';
    $newline  = "\r\n";
    my @bats;
    for my $bin (
        catfile($bin_dir, 'howdy'),
        catfile($bin_dir, 'foo', 'yay'),
    ) {
        my $bat = $bin . $suffix;
        cp $bin, $bat;
        push @bats => $bat;
    }
    END { unlink for @bats }
}
#END { remove_tree $tmpdir if -d $tmpdir }

ok my $ps = Pod::Site->new({
    favicon_uri  => 'favicon.ico',
    doc_root     => $doc_root,
    base_uri     => $base_uri,
    module_roots => [$mod_root, $bin_root],
    label        => 'API Browser',
}), 'Create Pod::Site object';

# Build it.
file_not_exists_ok $doc_root, 'Doc root should not yet exist';
ok $ps->build, 'Build the site';
file_exists_ok $doc_root, 'Doc root should now exist';

# Verify stuff in the object.
is_deeply $ps->mod_files, {
    'Heya' => {
        'Man' => {
            'What.pm' => catfile $mod_dir, qw(Heya Man What.pm)
        },
        'Man.pm' => catfile $mod_dir, qw(Heya Man.pm)
    },
    'Heya.pm' => catfile( $mod_dir, qw(Heya.pm)),
    'Foo' => {
        'Bar' => {
            'Baz.pm' => catfile($mod_dir, qw(Foo Bar Baz.pm))
        },
        'Shizzle.pm' => catfile($mod_dir, qw(Foo Shizzle.pm)),
        'Bar.pm' => catfile $mod_dir, qw(Foo Bar.pm)
    },
    'Hello.pm' => catfile $mod_dir, qw(Hello.pm)
}, 'Should have a module tree';

is_deeply $ps->bin_files, {
    'foo/yay' => catfile("$bin_dir/foo/yay$suffix"),
    'howdy'   => catfile("$bin_dir/howdy$suffix"),
    'yo'      => catfile("$bin_dir/yo.pl")
}, 'Should have bin files';

is $ps->main_module,   'Foo::Bar', 'Should have a main module';
is $ps->sample_module, 'Foo::Bar', 'Should have a sample module';
is $ps->name,          'Foo::Bar', 'Should have default name';

# Check for JavaScript and CSS files.
file_exists_ok catfile($doc_root, 'podsite.css'), 'CSS file should exist';
file_exists_ok catfile($doc_root, 'podsite.js'),  'JS file should exist';

# Check for Pod::Simple::XHTML-generated files.
for my $file (
    catfile(qw(Heya Man What.html)),
    catfile(qw(Heya Man.html)),
    catfile(qw(Heya.html)),
    catfile(qw(Foo Bar Baz.html)),
    catfile(qw(Foo Shizzle.html)),
    catfile(qw(Foo Bar.html)),
    catfile(qw(Hello.html)),
    'howdy.html',
    'yo.html',
    catfile(qw(foo yay.html)),
) {
    file_exists_ok catfile($doc_root, $file), "$file should exist";
}

##############################################################################
# Validate the index page.

ok my $tx = Test::XPath->new(
    file    => catfile($doc_root, 'index.html'),
    is_html => 1
), 'Load index.html';

# Some basic sanity-checking.
$tx->is( 'count(/html)',      1, 'Should have 1 html element' );
$tx->is( 'count(/html/head)', 1, 'Should have 1 head element' );
$tx->is( 'count(/html/body)', 1, 'Should have 1 body element' );
$tx->is( 'count(/html/*)', 2, 'Should have 2 elements in html' );
$tx->is( 'count(/html/head/*)', 7, 'Should have 7 elements in head' );

# Check the head element.
$tx->is(
    '/html/head/meta[@http-equiv="Content-Type"]/@content',
    'text/html; charset=UTF-8',
    'Should have the content-type set in a meta header',
);
$tx->is(
    '/html/head/title',
    $ps->title,
    'Title should be corect'
);
$tx->is(
    '/html/head/meta[@name="base-uri"]/@content',
    $base_uri,
    'base-uri should be corect'
);
$tx->is(
    '/html/head/link[@type="text/css"][@rel="stylesheet"]/@href',
    'podsite.css',
    'Should load the CSS',
);
$tx->is(
    '/html/head/link[@type="img/ico"][@rel="icon"]/@href',
    'favicon.ico',
    'Should load the favicon',
);
$tx->is(
    '/html/head/script[@type="text/javascript"]/@src',
    'podsite.js',
    'Should load the JS',
);
$tx->is(
    '/html/head/meta[@name="generator"]/@content',
    ref($ps) . ' ' . ref($ps)->VERSION,
    'The generator meta tag should be present and correct'
);

# Check the body element.
$tx->is( 'count(/html/body/div)', 2, 'Should have 2 top-level divs' );
$tx->ok( '/html/body/div[@id="nav"]', 'Should have nav div', sub {
    $_->is('./h3', $ps->nav_header, 'Should have title header');

    $_->ok('./ul[@id="tree"]', 'Should have tree ul', sub {
        $_->is('count(./li)', 5, 'Should have five nav list items');

        # Check TOC.
        $_->is('./li[1]/@id', 'toc', 'The first should be the TOC');
        $_->ok('./li[@id="toc"]', 'Should have toc li', sub {
            $_->is('./a[@href="toc.html"]', 'TOC', 'Should have TOC item');
        });

        # Check first nav link.
        $_->is('./li[2]/@id', 'Foo', 'Second li should be Foo');
        $_->is('count(./li[2]/*)', 1, 'It should have one subelement');
        $_->like('./li[2]', qr/Foo$newline/, 'It should be labled "Foo"');
        $_->ok('./li[2]/ul', 'It should be an unordered list', sub {
            $_->is(
                'count(./*)', 2,
                'That unordered list should have two subelements'
            );
            $_->is(
                'count(./li)', 2, 'Both should be li elements'
            );
            $_->ok('./li[@id="Foo::Bar"]', 'The first should be the Foo::Bar item', sub {
                $_->is(
                    'count(./*)', 2, 'Which should have two subelements'
                );
                $_->is(
                    './a[@href="Foo/Bar.html"]', 'Bar', 'One should link to Bar'
                );
                $_->ok('./ul', 'The other should be an unordered list', sub {
                    $_->is(
                        'count(./*)', 1, 'It should have 1 subelement'
                    );
                    $_->ok(
                        './li[@id="Foo::Bar::Baz"]', 'Which should be an li', sub {
                            $_->is('count(./*)', 1, 'That li should have one sub');
                            $_->is(
                                './a[@href="Foo/Bar/Baz.html"]', 'Baz',
                                'Which should link to Baz'
                            );
                    });
                });
            });

            $_->ok(
                './li[@id="Foo::Shizzle"]',
                'The second should be the Foo::Shizzle item',
                sub {
                    $_->is(
                        'count(./*)', 1, 'It should have 1 subelement'
                    );
                    $_->is(
                        './a[@href="Foo/Shizzle.html"]', 'Shizzle',
                        'Which should link to Shizzle'
                    );
                },
            );
        });

        # Look at the second nav link.
        $_->is('./li[3]/@id', 'Hello', 'third li should be Hello');
        $_->is('count(./li[3]/*)', 1, 'It should have one subelement');
        $_->is(
            './li/a[@href="Hello.html"]', 'Hello',
            'Which should be a link to Hello'
        );

        # And the fourth nav link.
        $_->is('./li[4]/@id', 'Heya', 'Fourth li should be Heya');
        $_->ok('./li[4]', 'Look at those subelements', sub {
            $_->is('count(./*)', 2, 'It should have two subelements');
            $_->is('./a[@href="Heya.html"]', 'Heya', 'First should link to Heya');
            $_->ok('./ul', 'Second should be a ul', sub {
                $_->is('count(./*)', 1, 'It should have one subelement');
                $_->ok('./li[@id="Heya::Man"]', 'It should be the Heya::Man li', sub {
                    $_->is('count(./*)', 2, 'It should have two subelements');
                    $_->is(
                        './a[@href="Heya/Man.html"]', 'Man',
                        'One should link to Heya::Man'
                    );
                    $_->ok('./ul', 'Second should be a ul', sub {
                        $_->is('count(./*)', 1, 'It should have one subelement');
                        $_->ok(
                            './li[@id="Heya::Man::What"]',
                            'It should be the Heya::Man::What li', sub {
                                $_->is(
                                    './a[@href="Heya/Man/What.html"]', 'What',
                                    'It should link to Heya::Man::What'
                                );
                            }
                        );
                    });
                });
            });
        });

        # And finally the fifth nav link.
        $_->is('./li[5]/@id', 'bin', 'Fifth li should be bin');
        $_->ok('./li[5]', 'Look at its elements', sub {
            $_->is('count(./*)', 1, 'It should have one');
            $_->ok('./ul', 'It should be a ul', sub {
                $_->is('count(./*)', 3, 'Which should have 3 children');
                $_->is('count(./li)', 3, 'All three should be li');

                $_->is('./li[1]/@id', 'foo/yay', 'The second one should be yay');
                $_->is('count(./li[1]/*)', 1, 'Which should have 1 child');
                $_->is('./li[1]/a[@href="foo/yay.html"]', 'foo/yay', 'Which should link to yay');

                $_->is('./li[2]/@id', 'howdy', 'The first one should be howdy');
                $_->is('count(./li[2]/*)', 1, 'Which should have 1 child');
                $_->is('./li[2]/a[@href="howdy.html"]', 'howdy', 'Which should link to howdy');

                $_->is('./li[3]/@id', 'yo', 'The third one should be yo.pl');
                $_->is('count(./li[3]/*)', 1, 'Which should have 1 child');
                $_->is('./li[3]/a[@href="yo.html"]', 'yo', 'Which should link to yo');
            });
        });
    });
});

# Validate doc div.
$tx->ok('/html/body/div[@id="doc"]', 'Should have doc div', sub {
    $_->is('.', '', 'Which should be empty');
    $_->is('count(./*)', 0, 'And should have no subelements');
});
$tx->is('/html/body/div[last()]/@id', 'doc', 'Which should be last');

##############################################################################
# Validate the TOC.
ok $tx = Test::XPath->new(
    file => catfile($doc_root, 'toc.html'),
    is_html => 1
), 'Load toc.html';

# Some basic sanity-checking.
$tx->is( 'count(/html)',      1, 'Should have 1 html element' );
$tx->is( 'count(/html/head)', 1, 'Should have 1 head element' );
$tx->is( 'count(/html/body)', 1, 'Should have 1 body element' );
$tx->is( 'count(/html/*)', 2, 'Should have 2 elements in html' );

# Check the head element.
$tx->is( 'count(/html/head/*)', 3, 'Should have 3 elements in head' );
$tx->is(
    '/html/head/meta[@http-equiv="Content-Type"]/@content',
    'text/html; charset=UTF-8',
    'Should have the content-type set in a meta header',
);

$tx->is( '/html/head/title', $ps->title, 'Title should be corect');

$tx->is(
    '/html/head/meta[@name="generator"]/@content',
    ref($ps) . ' ' . ref($ps)->VERSION,
    'The generator meta tag should be present and correct'
);

# Check the body.
$tx->is( 'count(/html/body/*)', 7, 'Should have 7 elements in body' );

# Headers.
$tx->is( 'count(/html/body/h1)', 2, 'Should have 2 h1 elements in body' );

$tx->is( '/html/body/h1[1]', $ps->title, 'Should have title in first h1 header');
$tx->is(
    '/html/body/h1[2]', 'Instructions',
    'Should have "Instructions" in second h1 header'
);

$tx->is( 'count(/html/body/h3)', 1, 'Should have 1 h3 element in body' );
$tx->is( '/html/body/h3', 'Classes & Modules', 'h3 should be correct');

# Paragraphs.
$tx->is( 'count(/html/body/p)', 2, 'Should have 2 p elements in body' );
$tx->like(
    '/html/body/p[1]', qr/^Select class names/,
    'First paragraph should look right'
);

$tx->is(
    '/html/body/p[2]', 'Happy Hacking!', 'Second paragraph should be right'
);

# Example list.
$tx->is( 'count(/html/body/ul)', 2, 'Should have 2 ul elements in body' );
$tx->ok('/html/body/ul[1]', sub {
    $_->is('count(./li)', 2, 'Should have two list items');
    $_->is('count(./li/a)', 2, 'Both should have anchors');
    $_->is(
        './li/a[@href="./?Foo::Bar"]', '/?Foo::Bar',
        'First link should be correct'
    );
    $_->is(
        './li/a[@href="./Foo::Bar"]', '/Foo::Bar',
        'Second link should be correct'
    );
}, 'Should have first unordered list');

# Class list.
$tx->ok('/html/body/ul[2]', 'Should have second unordered list', sub {
    $_->is('count(./*)',  10, 'It should have seven subelements');
    $_->is('count(./li)', 10, 'All of which should be li');

    my $i = 0;
    for my $link(
        [ 'Foo::Bar',        'Get the Foo out of the Bar!'     ],
        [ 'Foo::Bar::Baz',   'Bazzle your Bar, Foo!'           ],
        [ 'Foo::Shizzle',    'Get the Foo out of the Shizzle!' ],
        [ 'Hello',           'Hello World!'                    ],
        [ 'Heya',            "How *you* doin'?"                ],
        [ 'Heya::Man',       'Hey man, wassup?'                ],
        [ 'Heya::Man::What', 'Hey man, wassup, yo?'            ],
        [ 'foo/yay',         'This is the bar, foo'            ],
        [ 'howdy',           'Welcome my friend'               ],
        [ 'yo',              'Heya yourself'                   ],
    ) {
        ++$i;
        $_->ok("./li[$i]", "Check li #$i", sub {
            $_->is('count(./*)', 1, 'It should have one subelement');
            $_->is(
                '.', "$link->[0]—$link->[1]",
                q{It should have $link->[0]'s name and abstract}
            );
            (my $url = $link->[0]) =~ s{::}{/}g;
            $_->is(
                "./a[\@href='$url.html'][\@rel='section'][\@name='$link->[0]']",
                $link->[0], "Which should link to $link->[0]",
            );
        });
    }
});

# Verify that the XHTML output has been modified to our satisfaction.
ok $tx = Test::XPath->new(
    file => catfile($tmpdir, 'doc_root', 'Hello.html'),
    is_html => 1
), 'Load Hello.html';

# Some basic sanity-checking.
$tx->is( 'count(/html)',      1, 'Should have 1 html element' );
$tx->is( 'count(/html/head)', 1, 'Should have 1 head element' );
$tx->is( 'count(/html/body)', 1, 'Should have 1 body element' );
$tx->is( 'count(/html/*)', 2, 'Should have 2 elements in html' );

# Check the head element.
$tx->is( 'count(/html/head/*)', 3, 'Should have 3 elements in head' );
$tx->is(
    '/html/head/meta[@http-equiv="Content-Type"]/@content',
    'text/html; charset=UTF-8',
    'Should have the content-type set in a meta header',
);

$tx->is( '/html/head/title', 'Hello', 'POD title should be corect');

$tx->is(
    '/html/head/meta[@name="generator"]/@content',
    ref($ps) . ' ' . ref($ps)->VERSION,
    'The generator meta tag should be present and correct'
);

# Check the body.
$tx->is('/html/body/@class', 'pod', 'Body class should be "pod"');

# Check that verbatim indentation is properly stripped.
$tx->is(
    '//pre/code',
    "my \$hey = Hello->new;${newline}${newline}say \$hey->sup${newline}    if 1;",
    'Verbatim secton should have leading spaces stripped'
);

# Check that a local link is correct.
$tx->is(
    '/html/body/ul[2]/li[1]/p/a[@rel="section"]/@href',
    '/docs/Heya/Man.html',
    'Local link href should be correct',
);

$tx->is(
    '/html/body/ul[2]/li[1]/p/a[@rel="section"]/@name',
    'Heya::Man',
    'Local link name should be correct',
);

$tx->is(
    '/html/body/ul[2]/li[1]/p/a[@rel="section"]',
    'Heya::Man',
    'Local link text should be correct',
);

# Remote link should go to search.cpan.org.
$tx->is(
    '/html/body/ul[2]/li[2]/p/a[@href="http://search.cpan.org/perldoc?Test::XPath"]',
    'Test::XPath',
    'Remote link should go to search.cpan.org'
);

# Check that local link with section is correct.
$tx->is(
    '/html/body/ul[2]/li[3]/p/a[@rel="subsection"]/@href',
    '/docs/Foo/Bar.html#NAME',
    'Local link with section should have correct href',
);

$tx->is(
    '/html/body/ul[2]/li[3]/p/a[@rel="subsection"]/@name',
    'Foo::Bar',
    'Local link with subsection name should be correct',
);

$tx->is(
    '/html/body/ul[2]/li[3]/p/a[@rel="subsection"]',
    '"NAME" in Foo::Bar',
    'Local link with subsection text should be correct',
);

# Check that local section is correct.
$tx->is(
    '/html/body/ul[2]/li[4]/p/a[@rel="subsection"]/@href',
    '#DESCRIPTION',
    'Local subsection should have correct href',
);

$tx->is(
    '/html/body/ul[2]/li[4]/p/a[@rel="subsection"]/@name',
    'Hello',
    'Local subsection name should be correct',
);

$tx->is(
    '/html/body/ul[2]/li[4]/p/a[@rel="subsection"]',
    '"DESCRIPTION"',
    'Local subsection text should be correct',
);
