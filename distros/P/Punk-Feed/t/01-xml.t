#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Feed ();

*esc = \&Punk::Plugin::Feed::_xml_escape;
*pct = \&Punk::Plugin::Feed::_pct_encode;
*url = \&Punk::Plugin::Feed::_url;

# The escaper returns the UTF-8 BYTES a document carries, not a character
# string, so an expectation holding a character above 127 has to be encoded to
# be compared with it. Without this the Char tests below compare "caf\x{e9}"
# against "caf\xc3\xa9" and report a filter bug that is not there.
sub u8 { my $s = shift; utf8::encode($s); return $s }

# ---- the five entities -----------------------------------------------------

is(esc('&'),  '&amp;',  'an ampersand');
is(esc('<'),  '&lt;',   'a less-than');
is(esc('>'),  '&gt;',   'a greater-than');
is(esc('"'),  '&quot;', 'a double quote');
is(esc("'"),  '&apos;', 'a single quote');

# Both quotes, so one function is safe in an attribute as well as in text.
is(esc(q{a "b" 'c'}), 'a &quot;b&quot; &apos;c&apos;',
    'both quote characters go, which is what makes this safe in an attribute');

is(esc('AT&T <b>x</b>'), 'AT&amp;T &lt;b&gt;x&lt;/b&gt;',
    'a run with several, in place');

# ---- the fast path ---------------------------------------------------------
#
# The escaper's common case is a `continue` per byte with no copy, and a bug
# there is silent: the string still comes back, just wrong. Assert the
# untouched case byte for byte.

is(esc('nothing to do here'), 'nothing to do here',
    'a string with nothing to escape comes back unchanged');
is(esc(''), '', 'and the empty string is the empty string');

{
    my $long = ('x' x 5000) . '&' . ('y' x 5000);
    is(esc($long), ('x' x 5000) . '&amp;' . ('y' x 5000),
        'one entity in the middle of a long run keeps both sides intact');
}

is(esc('&&&'), '&amp;&amp;&amp;', 'adjacent entities do not swallow each other');
is(esc('&x'),  '&amp;x',  'an entity at the start');
is(esc('x&'),  'x&amp;',  'an entity at the end');

# ---- already-escaped text is escaped again --------------------------------
#
# It has to be. The alternative is guessing whether a '&' begins an entity,
# and a title reading "Tom & Jerry &amp; friends" has both.

is(esc('&amp;'), '&amp;amp;',
    'an ampersand is escaped even when it looks like an entity already');

# ---- the CDATA decision, made testable ------------------------------------

is(esc(']]>'), ']]&gt;',
    "a ']]>' in content is escaped rather than carried inside CDATA");
like(esc('<script>a ]]> b</script>'), qr/\A&lt;script&gt;/,
    '  and content is escaped whole, so there is no CDATA to break out of');

# ---- the Char production ----------------------------------------------------
#
# XML 1.0 section 2.2 does not let a document carry every character perl can
# hold, and escaping is no help: &#1; and &#xD800; are as forbidden as the raw
# character, because a character reference may only name a character Char
# already allows. So they are DROPPED, and the five entities are only half of
# this function's job.
#
# Why it matters more here than in a page: a feed is one document. A single
# such character in one entry makes the whole thing fatally ill-formed, so a
# conforming reader loses every item rather than the offending one - and the
# bytes are cached and re-served for the whole ttl. A feed also routinely
# carries text its operator never wrote: comments, submitted posts, forum
# threads, uploaded file names.
#
#   Char ::= #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD]
#                                            | [#x10000-#x10FFFF]

# the three C0 characters that ARE allowed, which must survive: a summary
# with newlines in it is ordinary
is(esc("a\tb"),   "a\tb",   'a tab is Char and survives');
is(esc("a\nb"),   "a\nb",   'a newline is Char and survives');
is(esc("a\x0db"), "a\x0db", 'a carriage return is Char and survives');

# the rest of C0 is not
is(esc("a\x00b"), 'ab', 'a NUL is dropped');
is(esc("a\x01b"), 'ab', 'a SOH is dropped');
is(esc("a\x08b"), 'ab', 'a backspace is dropped');
is(esc("a\x0bb"), 'ab', 'a vertical tab is dropped');
is(esc("a\x0cb"), 'ab', 'a form feed is dropped');
is(esc("a\x1fb"), 'ab', 'a unit separator is dropped');

# and DEL is NOT excluded by Char, however much it looks like it should be.
# pfeed_loc_ok rejects it for a path, which is a different rule for a
# different job; this function implements the production.
is(esc("a\x7fb"), "a\x7fb", 'DEL is Char, so it stays - the production says so');

# the surrogates, which are the half a byte-wise C0 filter would miss
{
    no warnings 'utf8';
    is(esc("a\x{d800}b"), 'ab', 'the first surrogate is dropped');
    is(esc("a\x{dfff}b"), 'ab', 'the last surrogate is dropped');
    is(esc("a\x{e000}b"), u8("a\x{e000}b"), 'and U+E000 just past them stays');

    # the two BMP characters Char stops just short of
    is(esc("a\x{fffd}b"), u8("a\x{fffd}b"), 'U+FFFD is Char and stays');
    is(esc("a\x{fffe}b"), 'ab', 'U+FFFE is dropped');
    is(esc("a\x{ffff}b"), 'ab', 'U+FFFF is dropped');

    # the top of Unicode, and perl's willingness to go past it
    is(esc("a\x{10ffff}b"), u8("a\x{10ffff}b"), 'U+10FFFF is Char and stays');
    is(esc("a\x{110000}b"), 'ab',
        'U+110000 is dropped: perl encodes it, Unicode does not have it, and '
        . 'XML cannot carry it');
    is(esc("a\x{7fffffff}b"), 'ab',
        'and so is a codepoint needing one of perl\'s long forms, whose '
        . 'bytes must be stepped over as a unit rather than one at a time');
}

# a character that is legal stays byte-identical, so the filter is not
# quietly mangling ordinary text on its way past
is(esc("caf\x{e9}"), u8("caf\x{e9}"), 'an accented character is untouched');
is(esc("\x{4e2d}\x{6587}"), u8("\x{4e2d}\x{6587}"), 'and so is CJK');
is(esc("\x{1f600}"), u8("\x{1f600}"), 'and so is an astral emoji');

# U+0080 is a C1 control and Char DOES allow it - the production excludes the
# C0 range and nothing above it until the surrogates. XML 1.1 would want it
# escaped; a feed is 1.0.
is(esc("a\x{80}b"), u8("a\x{80}b"), 'a C1 control is Char, so it stays');

# dropping and escaping in one string, so neither pass loses the other's work
{
    no warnings 'utf8';
    is(esc("A&B\x01C<D\x{d800}E"), 'A&amp;B' . 'C&lt;D' . 'E',
        'entities and drops interleave without disturbing each other');
}

# the run accumulator: a drop in the middle of a long run must keep both sides
{
    my $long = ('x' x 5000) . "\x01" . ('y' x 5000);
    is(esc($long), ('x' x 5000) . ('y' x 5000),
        'a dropped character in a long run keeps both sides intact');
}

is(esc("\x01"), '', 'a string of nothing but an illegal character empties');

# A BYTE STRING that is not UTF-8 still comes out legal, which is the half of
# this that was never broken: pfeed_u8 reads it as latin-1 and upgrades, so
# every byte becomes a codepoint below 256 and all but the C0 ones are Char.
# There is no reaching the escaper's malformed-sequence branch from perl
# because of that, which is why nothing below asserts on it - the branch is
# there so that a byte the escaper cannot read is dropped rather than emitted,
# not because an input can get to it.
{
    no warnings;
    is(esc("a\x80\x80b"), u8("a\x{80}\x{80}b"),
        'stray continuation bytes are read as latin-1 and come out as legal '
        . 'C1 characters, so they were never the route in');
    is(esc("a\x01\x80b"), u8("a\x{80}b"),
        '  ... and a C0 byte among them is still dropped');
}

# ---- percent-encoding ------------------------------------------------------

is(pct('/posts/1'), '/posts/1', 'an ordinary path is left alone');
is(pct('/a b'),     '/a%20b',   'a space is encoded');
is(pct('/a&b'),     '/a%26b',   'a sub-delimiter is encoded');
is(pct('/a-b_c.d~e'), '/a-b_c.d~e', 'the unreserved set survives');
is(pct('/'),        '/',        'the separator is kept, or it would not be a path');
is(pct("/a\x00b"),  '/a%00b',   'a NUL is encoded, not truncated at');

{
    my $utf8 = "/caf\xc3\xa9";           # café as UTF-8 bytes
    is(pct($utf8), '/caf%C3%A9', 'non-ASCII bytes become %XX, uppercase hex');
}

# ---- encode, then escape ---------------------------------------------------
#
# The order is the point of the header. A '%' produced by the encoder must not
# then be escaped, and an '&' in the path must be encoded rather than turned
# into &amp; - those are different URLs.

is(url('https://example.com', '/a b'), 'https://example.com/a%20b',
    'a space in a path is encoded, and the % it produced is left alone');

is(url('https://example.com', '/a&b'), 'https://example.com/a%26b',
    'an ampersand in a path is ENCODED, not escaped - &amp; would be a '
  . 'different URL');

is(url('https://example.com', '/<x>'), 'https://example.com/%3Cx%3E',
    'angle brackets in a path are encoded, so nothing reaches the escaper');

is(url('https://example.com', '/posts/1'), 'https://example.com/posts/1',
    'an ordinary URL is joined and left alone');

# ---- a query string must survive as one ------------------------------------
#
# Path rules applied to a query encode the '?' and fold the query into the
# path, so /article?id=5 asks for a file literally named "article?id=5" - a 404
# for every subscriber, from a link that looks right in the document.

is(url('https://example.com', '/article?id=5'),
   'https://example.com/article?id=5',
   'the query separator is not encoded');

is(url('https://example.com', '/a?x=1&y=2'),
   'https://example.com/a?x=1&amp;y=2',
   "a query's & is ESCAPED to &amp; - which in XML is the character '&' - "
 . 'rather than encoded to %26, which would be a different URL');

is(url('https://example.com', '/a?q=hello world'),
   'https://example.com/a?q=hello%20world',
   'a space in a query is still encoded');

is(url('https://example.com', '/a#frag'), 'https://example.com/a%23frag',
   'a bare fragment with no query is path-encoded');

is(url('https://example.com', '/a?x=1#frag'),
   'https://example.com/a?x=1#frag',
   'a fragment after a query survives');

# The path half keeps its conservative rules: over-encoding there is safe
# because the server decodes it back to the same path.
is(url('https://example.com', '/a&b?x=1'), 'https://example.com/a%26b?x=1',
   'an & before the ? is still encoded, because that half is a path');

# The base is configuration and is not encoded - encoding it would turn the
# "://" into something no reader would follow.
is(url('https://example.com', '/x'), 'https://example.com/x',
    'the scheme separator in the base survives');

done_testing;
