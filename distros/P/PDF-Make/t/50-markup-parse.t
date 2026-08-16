#!perl

# The markup parser.
#
# Two things are being pinned down here. First, that valid markup produces the
# tree the builder expects. Second, and more important, that invalid markup
# produces an error with a position rather than a guess: this parser is the
# one component that eats bytes written by whoever is holding the template,
# and "renders something slightly wrong" is the failure mode that reaches a
# customer with a number on it.

use strict;
use warnings;
use Test::More;
use PDF::Make::Markup::Parse;

sub parse_ok {
    my ($src, $name) = @_;
    my $r = PDF::Make::Markup::Parse->check($src);
    ok $r->{ok}, $name or diag "unexpected error: $r->{error} at $r->{line}:$r->{col}";
    return $r->{root};
}

sub parse_err {
    my ($src, $like, $name, %pos) = @_;
    my $r = PDF::Make::Markup::Parse->check($src);
    if ($r->{ok}) {
        fail $name;
        diag 'expected a parse error, got a tree';
        return;
    }
    like $r->{error}, $like, $name;
    is $r->{line}, $pos{line}, "  reported line $pos{line}" if exists $pos{line};
    is $r->{col},  $pos{col},  "  reported column $pos{col}" if exists $pos{col};
    return $r;
}

# ---- shape ------------------------------------------------------------------

subtest 'a document is a tree of elements and text' => sub {
    my $root = parse_ok(qq{<doc size="A4" margin="36">\n  <h1>Invoice</h1>\n</doc>},
                        'parses');
    is $root->{tag}, 'doc', 'root is doc';
    is $root->{attrs}{size}, 'A4', 'attribute read';
    is $root->{attrs}{margin}, '36', 'second attribute read';
    is scalar @{ $root->{children} }, 1, 'indentation between children dropped';

    my $h1 = $root->{children}[0];
    is $h1->{tag}, 'h1', 'child is h1';
    is $h1->{line}, 2, 'line recorded';
    is $h1->{children}[0]{text}, 'Invoice', 'text content';
};

subtest 'inline runs keep the whitespace around them' => sub {
    my $root = parse_ok('<doc><text>Total <b>due</b> now</text></doc>', 'parses');
    my @kids = @{ $root->{children}[0]{children} };
    is scalar @kids, 3, 'text, element, text';
    is $kids[0]{text}, 'Total ', 'leading run keeps its trailing space';
    is $kids[1]{tag}, 'b', 'the inline element';
    is $kids[2]{text}, ' now', 'trailing run keeps its leading space';
};

subtest 'void elements take no children' => sub {
    parse_ok('<doc><hr /><pagebreak/><hr></doc>', 'self-closed and bare both parse');
    parse_ok('<doc><hr></hr></doc>', 'an immediate close is tolerated');
    parse_err('<doc><hr>text</hr></doc>', qr/takes no children/,
              'content inside a void element is an error');
};

subtest 'comments are skipped, anywhere' => sub {
    my $root = parse_ok(
        qq{<!-- before -->\n<doc><!-- inside --><h1>x</h1></doc>\n<!-- after -->},
        'comments around and inside the root');
    is scalar @{ $root->{children} }, 1, 'comment left no node behind';
    parse_err('<doc><!-- unterminated </doc>', qr/unterminated comment/,
              'an unterminated comment is an error');
};

# ---- entities ---------------------------------------------------------------

subtest 'entities' => sub {
    my $root = parse_ok(
        '<doc><text>a &amp; b &lt; c &gt; d &quot;e&quot; &apos;f&apos;</text></doc>',
        'named entities');
    is $root->{children}[0]{children}[0]{text}, q{a & b < c > d "e" 'f'},
        'decoded';

    $root = parse_ok('<doc><text>&#65;&#x42;&#163;&#x20AC;</text></doc>',
                     'numeric references');
    my $t = $root->{children}[0]{children}[0]{text};
    is $t, "AB\x{a3}\x{20ac}", 'decimal, hex, latin-1 and BMP all decode';
    ok utf8::is_utf8($t), 'and the result is character data, not bytes';

    parse_err('<doc><text>&nbsp;</text></doc>', qr/unknown entity/,
              'no entity table beyond the five');
    parse_err('<doc><text>a & b</text></doc>', qr/unterminated entity/,
              'a bare ampersand is an error, and says to write &amp;');
    parse_err('<doc><text>&#xD800;</text></doc>', qr/not a valid code point/,
              'a surrogate is rejected');
    parse_err('<doc><text>&#0;</text></doc>', qr/not a valid code point/,
              'NUL is rejected');
    parse_err('<doc><text>&#;</text></doc>', qr/empty character reference/,
              'an empty reference is rejected');
    parse_err('<doc><text>&#99999999999;</text></doc>', qr/out of range/,
              'an absurd code point is rejected rather than wrapping');
};

# ---- errors carry a position ------------------------------------------------

subtest 'errors report where they happened' => sub {
    parse_err(qq{<doc>\n  <h1>a</h1>\n  <dvi>x</dvi>\n</doc>},
              qr/unknown tag '<dvi>'/, 'unknown tag', line => 3, col => 3);

    parse_err(qq{<doc>\n  <row>\n    <cell>x</row>\n  </row>\n</doc>},
              qr{</row> closes <cell> opened at line 3},
              'mismatched close names both tags and the opening line');

    # A missing </row> is discovered when </doc> arrives, and saying which
    # element it actually closed is more use than "unclosed" on its own.
    parse_err(qq{<doc>\n  <row>\n    <cell>x</cell>\n</doc>},
              qr{</doc> closes <row> opened at line 2},
              'a forgotten close is reported against the tag that found it');

    parse_err(qq{<doc>\n  <row>\n    <cell>x</cell>},
              qr/unclosed <row> opened at line 2/,
              'and at end of input it is reported as unclosed');

    parse_err('<doc><h1 class=big>x</h1></doc>',
              qr/must be quoted/, 'unquoted attribute value');

    parse_err('<doc><h1 hidden>x</h1></doc>',
              qr/has no value/, 'valueless attribute, with the fix in the message');

    parse_err('<doc><h1 a="1" a="2">x</h1></doc>',
              qr/duplicate attribute 'a'.*first at line 1/,
              'a repeated attribute is refused rather than silently resolved');

    parse_err('<doc><img src="a<b" /></doc>',
              qr/'<' inside the value of attribute/, 'a raw < inside an attribute value');

    parse_err('<doc><h1 a="unterminated></doc>',
              qr/opening quote is probably unclosed/,
              'an unclosed quote leads with the likely cause, not the rare one');

    parse_err('<doc><h1 a="unterminated',
              qr/unterminated value/,
              'and at end of input it is reported as unterminated');
};

subtest 'the root must be doc' => sub {
    parse_err('<h1>x</h1>', qr/root element must be <doc>/, 'wrong root');
    parse_err('', qr/empty document/, 'empty input');
    parse_err('   ', qr/empty document/, 'whitespace only');
    parse_err('hello', qr/text outside <doc>/, 'bare text');
    parse_err('<doc></doc><doc></doc>', qr/content after <\/doc>/,
              'a second root');
    parse_err('<doc></doc> trailing', qr/content after <\/doc>/,
              'trailing text');
};

subtest 'declarations and instructions are not part of the language' => sub {
    parse_err('<?xml version="1.0"?><doc></doc>', qr/root element must be <doc>/,
              'an XML declaration is not accepted');
    parse_err('<doc><!DOCTYPE html></doc>', qr/not part of this markup/,
              'nor a doctype');
};

subtest 'depth is bounded' => sub {
    my $deep = '<doc>' . ('<box>' x 70) . 'x' . ('</box>' x 70) . '</doc>';
    parse_err($deep, qr/nested deeper than 64/, 'deep nesting is refused');

    my $ok = '<doc>' . ('<box>' x 40) . 'x' . ('</box>' x 40) . '</doc>';
    parse_ok($ok, 'nesting within the limit is fine');
};

subtest 'a UTF-8 BOM is tolerated' => sub {
    parse_ok("\xEF\xBB\xBF<doc><h1>x</h1></doc>", 'BOM skipped (bytes)');
    parse_ok("\x{FEFF}<doc><h1>x</h1></doc>",     'BOM skipped (characters)');
};

subtest 'characters in, characters out, whichever way they arrive' => sub {
    my $want = "caf\x{e9} \x{20ac}1,240 \x{4e2d}\x{6587}";
    my $chars = "<doc><text>$want</text></doc>";
    my $bytes = $chars;
    utf8::encode($bytes);

    for my $case (['character string', $chars], ['UTF-8 bytes', $bytes]) {
        my ($name, $src) = @$case;
        my $root = parse_ok($src, "parses a $name");
        my $got  = $root->{children}[0]{children}[0]{text};
        is $got, $want, "  round-trips through a $name";
        ok utf8::is_utf8($got), '  and comes back as characters';
    }
};

subtest 'invalid UTF-8 is refused with a position' => sub {
    parse_err("<doc><text>bad \xff byte</text></doc>",
              qr/invalid UTF-8: unexpected byte 0xFF/,
              'a stray byte', line => 1, col => 16);
    parse_err("<doc><text>caf\xC3",
              qr/truncated sequence/, 'a sequence cut off by end of input');
    parse_err("<doc><text>\xC3</text></doc>",
              qr/not a continuation/,
              'a lead byte followed by something else names that instead');
    parse_err("<doc><text>\xC0\xAF</text></doc>",
              qr/overlong encoding/, 'an overlong form');
    parse_err("<doc><text>\xED\xA0\x80</text></doc>",
              qr/encoded surrogate/, 'a surrogate encoded as UTF-8');
    parse_err("<doc><text>\xE2\x28\xA1</text></doc>",
              qr/not a continuation/, 'a bad continuation byte');
};

# ---- the tag table ----------------------------------------------------------

subtest 'the tag table comes from the parser' => sub {
    my @tags = PDF::Make::Markup::Parse->tags;
    ok scalar @tags >= 25, 'the set is published';
    my %by = map { $_->{name} => $_ } @tags;
    ok $by{doc}{container},  'doc is a container';
    ok $by{hr}{void},        'hr is void';
    ok $by{b}{inline},       'b is inline';
    ok !$by{h1}{container},  'h1 is not a container';

    for my $t (@tags) {
        my $r = PDF::Make::Markup::Parse->check(
            $t->{name} eq 'doc' ? '<doc></doc>'
                                : "<doc><$t->{name}/></doc>");
        ok $r->{ok}, "<$t->{name}> is accepted by the parser it came from"
            or diag $r->{error};
    }
};

# ---- hostile input ----------------------------------------------------------

subtest 'malformed input never crashes, always explains' => sub {
    my @seeds = (
        qq{<doc size="A4">\n<h1>Invoice</h1>\n<table><tr><td>a</td></tr></table>\n</doc>},
        '<doc><text>Total <b>due</b> &amp; owing</text></doc>',
        '<doc><row><cell weight="2"><img src="logo"/></cell></row></doc>',
    );

    my $checked = 0;
    for my $seed (@seeds) {
        # every truncation
        for my $n (0 .. length($seed) - 1) {
            my $r = eval { PDF::Make::Markup::Parse->check(substr $seed, 0, $n) };
            $checked++;
            if (!defined $r) { fail "died on a truncation at $n: $@"; last }
            if (!$r->{ok}) {
                # an error must be usable: message, and a position inside the input
                last unless length $r->{error};
            }
        }

        # every single-byte deletion
        for my $n (0 .. length($seed) - 1) {
            my $mut = $seed;
            substr($mut, $n, 1) = '';
            my $r = eval { PDF::Make::Markup::Parse->check($mut) };
            $checked++;
            if (!defined $r) { fail "died on a deletion at $n: $@"; last }
        }

        # byte substitutions with the characters most likely to break a scanner
        for my $n (0 .. length($seed) - 1) {
            for my $c ('<', '>', '&', '"', "'", '/', ';', '#', "\0", "\xff") {
                my $mut = $seed;
                substr($mut, $n, 1) = $c;
                my $r = eval { PDF::Make::Markup::Parse->check($mut) };
                $checked++;
                if (!defined $r) {
                    fail "died substituting " . sprintf('%02x', ord $c) . " at $n: $@";
                    last;
                }
            }
        }
    }

    pass "survived $checked malformed inputs";
};

subtest 'pathological but well-formed input is bounded' => sub {
    my $many = '<doc>' . ('<hr/>' x 20000) . '</doc>';
    my $r = PDF::Make::Markup::Parse->check($many);
    ok $r->{ok}, '20k siblings parse';
    is scalar @{ $r->{root}{children} }, 20000, 'all of them';

    my $attrs = '<doc><h1 ' . join(' ', map { qq{a$_="$_"} } 1 .. 500) . '>x</h1></doc>';
    $r = PDF::Make::Markup::Parse->check($attrs);
    ok $r->{ok}, '500 attributes parse';
    is scalar keys %{ $r->{root}{children}[0]{attrs} }, 500, 'all of them';

    my $long = '<doc><text>' . ('word ' x 50000) . '</text></doc>';
    $r = PDF::Make::Markup::Parse->check($long);
    ok $r->{ok}, 'a quarter-megabyte text node parses';
};

subtest 'parse throws with the position in the message' => sub {
    eval { PDF::Make::Markup::Parse->parse(qq{<doc>\n  <nope/>\n</doc>}) };
    like $@, qr/markup error at line 2, column 3: unknown tag '<nope>'/,
        'the exception is the message an editor and a CI log both want';
};

done_testing;
