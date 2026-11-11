use strict;
use warnings;

use Open::This        qw( to_editor_args );
use Path::Tiny        qw( path );
use Test::Differences qw( eq_or_diff );
use Test::More import => [qw( done_testing )];
use Test::Warnings ();
use URI::Escape    qw( uri_escape );

# This gets really noisy on Travis if $ENV{EDITOR} is not set
local $ENV{EDITOR} = 'vim';

eq_or_diff(
    [
        to_editor_args(
            'https://github.com/oalders/open-this/blob/master/lib/Open/This.pm'
        )
    ],
    ['lib/Open/This.pm'],
    'full https GitHub URL'
);

eq_or_diff(
    [
        to_editor_args(
            'https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L75'
        )
    ],
    [ '+75', 'lib/Open/This.pm' ],
    'full https GitHub URL with fragment'
);

eq_or_diff(
    [
        to_editor_args(
            'https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L75-L80'
        )
    ],
    [ '+75', 'lib/Open/This.pm' ],
    'full https GitHub URL with fragment and line range'
);

eq_or_diff(
    [
        to_editor_args(
            'https://github.com/oalders/open-this/blob/master/lib/Open/This.pm#L75x'
        )
    ],
    ['lib/Open/This.pm'],
    'full https GitHub URL with invalid fragment'
);

my @forge_urls = (
    [
        'https://codeberg.org/o/open-this/src/branch/main/lib/Open/This.pm#L75',
        [ '+75', 'lib/Open/This.pm' ],
        'Codeberg src/branch URL'
    ],
    [
        'https://codeberg.org/o/open-this/src/commit/8ce746e/lib/Open/This.pm#L75',
        [ '+75', 'lib/Open/This.pm' ],
        'Codeberg src/commit URL'
    ],
    [
        'https://codeberg.org/o/open-this/src/tag/v1.0/lib/Open/This.pm#L75',
        [ '+75', 'lib/Open/This.pm' ],
        'Codeberg src/tag URL'
    ],
    [
        'https://gitlab.com/group/sub/repo/-/blob/main/lib/Open/This.pm#L75',
        [ '+75', 'lib/Open/This.pm' ],
        'GitLab -/blob URL with subgroup'
    ],
    [
        'https://bitbucket.org/o/open-this/src/main/lib/Open/This.pm#lines-75',
        [ '+75', 'lib/Open/This.pm' ],
        'Bitbucket src URL'
    ],
    [
        'https://bitbucket.org/o/open-this/src/main/lib/Open/This.pm#lines-10:20',
        [ '+10', 'lib/Open/This.pm' ],
        'Bitbucket src URL with line range'
    ],
    [
        'https://git.sr.ht/~user/repo/tree/main/item/lib/Open/This.pm#L75',
        [ '+75', 'lib/Open/This.pm' ],
        'SourceHut tree/item URL'
    ],
    [
        'https://github.com/o/open-this/blob/main/lib/Open/This.pm#L5',
        [ '+5', 'lib/Open/This.pm' ],
        'single-digit #L line anchor'
    ],
    [
        'https://gitlab.com/g/open-this/-/blob/main/lib/Open/This.pm#L75-80',
        [ '+75', 'lib/Open/This.pm' ],
        'line range tail without a second L'
    ],
    (
        map { [ $_, ['lib/Open/This.pm'], "fragment ignored in $_" ] } (
            'https://bitbucket.org/o/open-this/src/main/lib/Open/This.pm#lines-75x',
            'https://bitbucket.org/o/open-this/src/main/lib/Open/This.pm#lines-',
            'https://gitlab.com/g/open-this/-/blob/main/lib/Open/This.pm#readme',
            'https://github.com/o/open-this/blob/main/lib/Open/This.pm#5',
        )
    ),
    [
        'https://github.com/o/open-this/blob/main/t/test-data/file%20with%20spaces',
        ['t/test-data/file with spaces'],
        'percent-encoded path is decoded'
    ],
    [
        'https://github.com/o',
        [],
        'URL too short to name a file'
    ],
    [
        'https://github.com/o/r/blob/main/lib/Open/This.pm/',
        ['lib/Open/This.pm'],
        'trailing slash is ignored'
    ],
    [
        'https://github.com/o/r/blob/main//lib/Open/This.pm',
        ['lib/Open/This.pm'],
        'empty segment from // is ignored'
    ],
    (
        map {
            [
                "https://github.com/o/r/blob/main/$_", [],
                "no traversal via $_"
            ]
        } 't/../lib/Open/This.pm',
        't%2F..%2Flib/Open/This.pm',
        uri_escape( path('lib/Open/This.pm')->absolute, '^A-Za-z0-9._~-' ),
    ),

    # Test::Warnings catches a regression: Path::Tiny warns on NUL
    [
        'https://github.com/o/r/blob/main/lib/Open/This.pm%00x',
        [],
        'NUL in a path names no file'
    ],
    map { [ $_, [], "no file in $_" ] } qw(
        https://github.com/o/r/blob/main
        https://gitlab.com/g/r/-
        https://codeberg.org/o/r/src
        https://git.sr.ht/~u/r/tree
    ),
);

for my $case (@forge_urls) {
    my ( $url, $expected, $name ) = @$case;
    eq_or_diff( [ to_editor_args($url) ], $expected, $name );
}

eq_or_diff(
    [ to_editor_args('HTTP::FakeTestClass') ],
    ['t/lib/HTTP/FakeTestClass.pm'],
    'non-URL package name starting with HTTP gets handled properly'
);

my $f    = 'lib/Open/This.pm';
my $path = "/o/r/blob/main/$f";

for my $case (
    [ "https://example.com:8443$path",              [$f] ],
    [ "https://example.com:8443$path#L75",          [ '+75', $f ] ],
    [ "https://example.com:8443$path:17",           [ '+17', $f ] ],
    [ "https://example.com:8443$path line 5",       [ '+5',  $f ] ],
    [ "https://user:123\@example.com$path",         [$f] ],
    [ "https://user:123\@example.com:8443$path#L9", [ '+9', $f ] ],
    [ "HTTPS://EXAMPLE.com:8443$path",              [$f] ],
    [ "http://[::1]:8443$path",                     [$f] ],
    [ 'https://example.com:8443/',                  [] ],
) {
    my ( $url, $expected ) = @$case;
    eq_or_diff( [ to_editor_args($url) ], $expected, $url );
}

done_testing();
