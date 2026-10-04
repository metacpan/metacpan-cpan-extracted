#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();
use Punk::Plugin::Feed ();

# A rendered document must hold only characters XML 1.0 section 2.2 allows, in
# EVERY field, in both formats.
#
# t/01-xml.t asserts the escaper against the Char production directly. This
# file asserts the thing that actually ships: that every free-text field
# reaches that escaper, so none of them is a route round it. The escaper being
# right is worth nothing if `author` or a `category` is emitted by some other
# path, and the only way to know is to put a hostile character in each field in
# turn and read the bytes that come out.
#
# Why this is fatal rather than cosmetic: a feed is ONE document. One such
# character in one entry makes the whole thing ill-formed, so a conforming
# reader drops every item rather than the offending one, and the bytes are
# cached and re-served for the whole ttl. A feed also carries text its operator
# never wrote - comments, submitted posts, forum threads, uploaded file names -
# so "do not put a control character in your title" is not a rule anyone is in
# a position to follow.
#
#   Char ::= #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD]
#                                            | [#x10000-#x10FFFF]

# The validator is pure perl and deliberately independent of the C: a test that
# asked the C whether the C was right would pass by construction. It decodes
# the document's own bytes and names the first codepoint Char forbids.
sub first_bad {
    my ($bytes) = @_;
    my $chars = $bytes;
    unless (utf8::decode($chars)) {
        # not decodable as UTF-8, which is its own failure and one t/12 covers
        return 'the document is not valid UTF-8';
    }
    my $i = 0;
    for my $c (split //, $chars) {
        my $n = ord $c;
        $i++;
        next if $n == 0x09 || $n == 0x0A || $n == 0x0D;
        next if $n >= 0x20    && $n <= 0xD7FF;
        next if $n >= 0xE000  && $n <= 0xFFFD;
        next if $n >= 0x10000 && $n <= 0x10FFFF;
        return sprintf 'U+%04X at character %d', $n, $i;
    }
    return undef;
}

# prove the validator can fail, or every assertion below is decoration
{
    is(first_bad("ok\tok\n"), undef, 'the validator passes legal text');
    like(first_bad("bad\x01here"), qr/U\+0001/,
        'and names a C0 control, so it is capable of failing');
    my $sur = "bad\x{d800}here";
    utf8::encode($sur);
    like(first_bad($sur), qr/U\+D800/, 'and a surrogate');
}

our @ROWS;
our %OPTS;
my $N = 0;

sub docs {
    my ($rows, %opts) = @_;
    local @ROWS = @$rows;
    local %OPTS = (title => 'Example', %opts);
    my $pkg = 'FeedChar' . ++$N;
    eval "package $pkg;\nuse Punk;\nuse Punk::Plugin::Feed;\n"
       . "host 'https://example.com';\n"
       . "plugin 'Feed' => { \%main::OPTS };\n"
       . "feed sub { \@main::ROWS };\n1" or die $@;
    $pkg->to_app;
    my $app = $pkg->punk_app;
    return (Punk::Plugin::Feed::_doc($app, undef, 'atom'),
            Punk::Plugin::Feed::_doc($app, undef, 'rss'));
}

# The characters an operator never typed and a commenter might.
my @HOSTILE = (
    [ 'U+0001'   => "\x01"        ],
    [ 'U+0000'   => "\x00"        ],
    [ 'U+000B'   => "\x0b"        ],
    [ 'U+001F'   => "\x1f"        ],
    [ 'U+FFFE'   => "\x{fffe}"    ],
    [ 'U+FFFF'   => "\x{ffff}"    ],
    [ 'U+D800'   => "\x{d800}"    ],
    [ 'U+DFFF'   => "\x{dfff}"    ],
    [ 'U+110000' => "\x{110000}"  ],
);

# Every free-text field, which is the point of the file. `loc` is absent on
# purpose: pfeed_loc_ok already refuses a path with a control character in it,
# and that refusal has its own test.
my @FIELDS = qw(title summary content author id);

for my $f (@FIELDS) {
    for my $case (@HOSTILE) {
        my ($name, $ch) = @$case;
        no warnings 'utf8';
        my @d = docs([{ loc => '/p/1', updated => '2019-03-04T05:06:07Z',
                        title => 'A title',
                        $f    => "before${ch}after" }]);
        my @fmt = qw(atom rss);
        for my $i (0, 1) {
            my $bad = first_bad($d[$i]);
            is($bad, undef, "$fmt[$i]: $name in `$f` does not reach the document")
                or diag "found $bad";
        }
    }
}

# the categories, which are a list and so a different code path.
#
# The field is `category`, singular, taking one string or an arrayref of them.
# Spelling it `categories` here made all eighteen of these assertions pass with
# the filter ABLATED, because an unknown key is simply not emitted and the
# hostile character never reached the document at all. Both forms are now
# driven, so a future rename cannot quietly empty this block again.
for my $case (@HOSTILE) {
    my ($name, $ch) = @$case;
    no warnings 'utf8';
    for my $shape (['one string', "bad${ch}one"],
                   ['a list', [ 'fine', "bad${ch}one" ]]) {
        my ($what, $val) = @$shape;
        my @d = docs([{ loc => '/p/1', updated => '2019-03-04T05:06:07Z',
                        title => 'A title', category => $val }]);
        for my $i (0, 1) {
            my $bad = first_bad($d[$i]);
            is($bad, undef, (qw(atom rss))[$i]
                . ": $name in a category as $what is filtered")
                or diag "found $bad";
        }
    }
}

# and the category really is reaching the document, so the block above is
# testing a field that exists rather than a key being ignored
{
    my @d = docs([{ loc => '/p/1', updated => '2019-03-04T05:06:07Z',
                    title => 'A title', category => [ 'alpha', 'beta' ] }]);
    for my $i (0, 1) {
        my $fmt = (qw(atom rss))[$i];
        like($d[$i], qr/alpha/, "$fmt: a category reaches the document");
        like($d[$i], qr/beta/,  "$fmt:   ... and so does a second one");
    }
}

# the enclosure, whose fields are emitted into ATTRIBUTES.
#
# ONE FIELD AT A TIME, because driving all of them together cannot tell which
# of them the filter is protecting. Putting the hostile character in all three
# at once passed this block with the filter ABLATED attributing the failure to
# `url` alone, while `length` contributed nothing at all - see below for why.
for my $f (qw(url type)) {
    for my $case (@HOSTILE) {
        my ($name, $ch) = @$case;
        no warnings 'utf8';
        my %enc = (url => 'https://example.com/a.mp3', type => 'audio/mpeg');
        $enc{$f} = $f eq 'url' ? "https://example.com/a${ch}.mp3"
                               : "audio/mpeg${ch}";
        my @d = docs([{ loc => '/p/1', updated => '2019-03-04T05:06:07Z',
                        title => 'A title', enclosure => \%enc }]);
        for my $i (0, 1) {
            my $bad = first_bad($d[$i]);
            is($bad, undef, (qw(atom rss))[$i]
                . ": $name in an enclosure `$f` is filtered")
                or diag "found $bad";
        }
    }
}

# `length` cannot carry one of these at all, and that is worth an assertion
# rather than a gap: it is read as an integer, so a non-numeric value becomes
# whatever SvIV makes of it long before the escaper sees anything. Driving a
# hostile character through it tested nothing AND warned "isn't numeric" on
# every row, which is how the vacuum was noticed.
{
    my @d = docs([{ loc => '/p/1', updated => '2019-03-04T05:06:07Z',
                    title => 'A title',
                    enclosure => { url    => 'https://example.com/a.mp3',
                                   length => 4096 } }]);
    for my $i (0, 1) {
        my $fmt = (qw(atom rss))[$i];
        is(first_bad($d[$i]), undef, "$fmt: an enclosure length is legal");
        like($d[$i], qr/length="4096"/, "$fmt:   ... and reaches the document");
    }
}

# the FEED-level fields, which come from configuration rather than a row - an
# operator can put a stray character in a title too, usually by pasting it
for my $case (@HOSTILE) {
    my ($name, $ch) = @$case;
    no warnings 'utf8';
    my @d = docs([{ loc => '/p/1', updated => '2019-03-04T05:06:07Z',
                    title => 'A title' }],
                 title => "Site${ch}Name");
    for my $i (0, 1) {
        my $bad = first_bad($d[$i]);
        is($bad, undef, (qw(atom rss))[$i] . ": $name in the feed title is filtered")
            or diag "found $bad";
    }
}

# and the legal characters are NOT filtered, so the whole file is not passing
# because the fields are being emptied
{
    my @d = docs([{ loc => '/p/1', updated => '2019-03-04T05:06:07Z',
                    title   => "Tabs\there",
                    summary => "Two\nlines",
                    author  => "Caf\x{e9} Owner" }]);
    for my $i (0, 1) {
        my $fmt = (qw(atom rss))[$i];
        is(first_bad($d[$i]), undef, "$fmt: a document of legal text is legal");
        like($d[$i], qr/Tabs\there/,  "$fmt:   ... and a tab survived");
        like($d[$i], qr/Two\nlines/,  "$fmt:   ... and a newline survived");
        like($d[$i], qr/Caf\xc3\xa9/, "$fmt:   ... and an accent survived");
    }
}

done_testing;
