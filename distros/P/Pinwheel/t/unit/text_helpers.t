#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 52;

use Pinwheel::Helpers::Text qw(h simple_format cycle pluralize ordinal_text);
use Pinwheel::View::String;


sub escape
{
    my $s = shift;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}


# HTML escaping
{
    # Null op with auto-escaping
    is(h('a&<>'), 'a&<>');
}

# Simple text markup (paragraphs and line breaks)
{
    my ($base, $fn);

    $base = Pinwheel::View::String->new('', \&escape);
    $fn = sub { ($base . simple_format(@_))->to_string() };

    is(&$fn(""), '<p></p>');
    is(&$fn("this"), '<p>this</p>');
    is(&$fn("\n\nthis"), '<p>this</p>');
    is(&$fn("this\n\n"), '<p>this</p>');
    is(&$fn("this\nthat"), "<p>this<br />\nthat</p>");
    is(&$fn("this & that"), "<p>this &amp; that</p>");
    is(&$fn("this\n\nthat"), "<p>this</p>\n<p>that</p>");
    is(&$fn("this  \n\n  that"), "<p>this</p>\n<p>that</p>");
    is(&$fn("this\n\n  \n\nthat"), "<p>this</p>\n<p>that</p>");
    is(&$fn("this\n&\nthat"), "<p>this<br />\n&amp;<br />\nthat</p>");
    is(&$fn("this\n\n&\n\nthat"), "<p>this</p>\n<p>&amp;</p>\n<p>that</p>");
    is(&$fn("this\nthat\n\nother"), "<p>this<br />\nthat</p>\n<p>other</p>");
    is(&$fn("a\n<b>"), "<p>a<br />\n&lt;b&gt;</p>");
    is(&$fn("a\r\n"), "<p>a</p>");
    is(&$fn("a\r\nb"), "<p>a<br />\nb</p>");
    is(&$fn("a\r\n\r\nb"), "<p>a</p>\n<p>b</p>");
}

# Cycles
{
    my $s;

    is(cycle(1, 2, 3), 1);
    is(cycle(1, 2, 3), 1);
    $s .= cycle(1, 2, 3) foreach (1 .. 5);
    is($s, '12312');
}

# Pluralize
{
    is(pluralize(1, 'Frog'), 'Frog');
    is(pluralize(2, 'Frog'), 'Frogs');
    is(pluralize(1, 'Person', 'People'), 'Person');
    is(pluralize(2, 'Person', 'People'), 'People');
}

# Ordinal text (ie, st, nd, rd, ...)
{
    is(ordinal_text(0), 'th');
    is(ordinal_text(1), 'st');
    is(ordinal_text(2), 'nd');
    is(ordinal_text(3), 'rd');
    is(ordinal_text(4), 'th');
    is(ordinal_text(10), 'th');
    is(ordinal_text(11), 'th');
    is(ordinal_text(12), 'th');
    is(ordinal_text(20), 'th');
    is(ordinal_text(21), 'st');
    is(ordinal_text('09'), 'th');
}

# Case conversion
{
    is(Pinwheel::Helpers::Text::uc('abc'), 'ABC');
    is(Pinwheel::Helpers::Text::lc('ABC'), 'abc');
    is(Pinwheel::Helpers::Text::tc('abc'), 'Abc');
    is(Pinwheel::Helpers::Text::tc('ABC'), 'Abc');
    is(Pinwheel::Helpers::Text::tc('two words'), 'Two Words');
    is(Pinwheel::Helpers::Text::tc('two-words'), 'Two-Words');
    is(Pinwheel::Helpers::Text::tc('two_words'), 'Two_words');
}

# Join arrays into a string
{
    my ($j);

    $j = \&Pinwheel::Helpers::Text::join;

    is(&$j([], ', '), '');
    is(&$j([], ', ', ' and '), '');

    is(&$j(['a'], ', '), 'a');
    is(&$j(['a'], ', ', ' and '), 'a');

    is(&$j(['a', 'b'], ', '), 'a, b');
    is(&$j(['a', 'b'], ', ', ' and '), 'a and b');

    is(&$j(['a', 'b', 'c'], ', '), 'a, b, c');
    is(&$j(['a', 'b', 'c'], ', ', ' and '), 'a, b and c');

    is(&$j(['a', 'b', 'c', 'd'], ', '), 'a, b, c, d');
    is(&$j(['a', 'b', 'c', 'd'], ', ', ' and '), 'a, b, c and d');
}
