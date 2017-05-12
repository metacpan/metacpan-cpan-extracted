#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 115;

use Pinwheel::TagSelect;


sub get_tokens
{
    my $lexer = Pinwheel::TagSelect::lexer(shift);
    my ($t, @tokens);
    while ($t = $lexer->()) {
        last if $t->[0] eq '';
        push @tokens, $t;
    }
    return \@tokens;
}


# Lexer
{
    my ($tokens, @x);

    $tokens = get_tokens("'test'");
    is_deeply($tokens, [['STR', "'test'"]]);
    $tokens = get_tokens('"test"');
    is_deeply($tokens, [['STR', '"test"']]);
    $tokens = get_tokens("\"test 'more'\"");
    is_deeply($tokens, [['STR', "\"test 'more'\""]]);

    $tokens = get_tokens('0');
    is_deeply($tokens, [['NUM', 0]]);
    $tokens = get_tokens('42');
    is_deeply($tokens, [['NUM', 42]]);

    $tokens = get_tokens('foo');
    is_deeply($tokens, [['ID', 'foo']]);
    $tokens = get_tokens('FOO');
    is_deeply($tokens, [['ID', 'FOO']]);
    $tokens = get_tokens('foo2');
    is_deeply($tokens, [['ID', 'foo2']]);
    $tokens = get_tokens('foo-bar');
    is_deeply($tokens, [['ID', 'foo-bar']]);

    $tokens = get_tokens('a|b');
    is_deeply($tokens, [['NSID', 'a|b']]);
    $tokens = get_tokens('foo|bar');
    is_deeply($tokens, [['NSID', 'foo|bar']]);

    $tokens = get_tokens('@foo');
    is_deeply($tokens, [['@ID', 'foo']]);
    $tokens = get_tokens('@FOO');
    is_deeply($tokens, [['@ID', 'FOO']]);
    $tokens = get_tokens('@foo2');
    is_deeply($tokens, [['@ID', 'foo2']]);
    $tokens = get_tokens('@foo-bar');
    is_deeply($tokens, [['@ID', 'foo-bar']]);

    $tokens = get_tokens('#foo');
    is_deeply($tokens, [['#ID', 'foo']]);
    $tokens = get_tokens('#FOO');
    is_deeply($tokens, [['#ID', 'FOO']]);
    $tokens = get_tokens('#foo2');
    is_deeply($tokens, [['#ID', 'foo2']]);
    $tokens = get_tokens('#foo-bar');
    is_deeply($tokens, [['#ID', 'foo-bar']]);

    $tokens = get_tokens('.foo');
    is_deeply($tokens, [['.ID', 'foo']]);
    $tokens = get_tokens('.FOO');
    is_deeply($tokens, [['.ID', 'FOO']]);
    $tokens = get_tokens('.foo2');
    is_deeply($tokens, [['.ID', 'foo2']]);
    $tokens = get_tokens('.foo-bar');
    is_deeply($tokens, [['.ID', 'foo-bar']]);

    $tokens = get_tokens('=');
    is_deeply($tokens, [['CMP', '=']]);
    $tokens = get_tokens('^=');
    is_deeply($tokens, [['CMP', '^=']]);
    $tokens = get_tokens('$=');
    is_deeply($tokens, [['CMP', '$=']]);
    $tokens = get_tokens('*=');
    is_deeply($tokens, [['CMP', '*=']]);
    $tokens = get_tokens('~=');
    is_deeply($tokens, [['CMP', '~=']]);
    $tokens = get_tokens('|=');
    is_deeply($tokens, [['CMP', '|=']]);

    $tokens = get_tokens(':');
    is_deeply($tokens, [[':', '']]);
    $tokens = get_tokens('.');
    is_deeply($tokens, [['.', '']]);
    $tokens = get_tokens('[ ]');
    is_deeply($tokens, [['[', ''], [']', '']]);
    $tokens = get_tokens('( )');
    is_deeply($tokens, [['(', ''], [')', '']]);
    @x = map { $_->[0] } @{get_tokens(':.[]>+~*')};
    is_deeply(\@x, [':', '.', '[', ']', '>', '+', '~', '*']);
}

# Parse element name
{
    my $fn = sub { Pinwheel::TagSelect::parse_element_name(Pinwheel::TagSelect::lexer(shift)) };

    is(&$fn('*'), '*');
    is(&$fn('foo'), 'foo');
    is(&$fn('+'), undef);
    is(&$fn('a|b'), 'a:b');
    is(&$fn('foo|bar'), 'foo:bar');
}

# Parse attribute
{
    my $fn = sub { Pinwheel::TagSelect::parse_attrib(Pinwheel::TagSelect::lexer(shift)) };

    is(&$fn('[a]'), '[@a]');
    is(&$fn('[a|b]'), '[@a:b]');
    is(&$fn('[a="b"]'), '[@a="b"]');
    is(&$fn("[a='b']"), "[\@a='b']");
    is(&$fn('[a^="b"]'), '[starts-with(@a,"b")]');
    is(&$fn('[a$="b"]'), '[substring(@a,string-length(@a)-0,1)="b"]');
    is(&$fn('[a$="\"b\""]'), '[substring(@a,string-length(@a)-2,3)="\"b\""]');
    is(&$fn('[a*="b"]'), '[contains(@a,"b")]');
    is(&$fn('[a~="b"]'), '[contains(concat(" ",@a," ")," b ")]');
    is(&$fn('[a|="b"]'), '[@a="b" or starts-with(@a,"b-")]');
    is(&$fn("[a|='b']"), "[\@a='b' or starts-with(\@a,'b-')]");

    eval { &$fn('x') };
    like($@, qr/expected \[/i);
    eval { &$fn('[@') };
    like($@, qr/expected attribute name/i);
    eval { &$fn('[a@') };
    like($@, qr/expected ] or comparison/i);
    eval { &$fn('[a=1]') };
    like($@, qr/expected string/i);
    eval { &$fn('[a="b"') };
    like($@, qr/expected ]/i);
}

# Parse pseudo elements/classes
{
    my $fn = sub { Pinwheel::TagSelect::parse_pseudo(Pinwheel::TagSelect::lexer(shift)) };

    is(&$fn(':first-child'), '[not(preceding-sibling::*)]');
    is(&$fn(':first-of-type'), '[position()=1]');
    is(&$fn(':last-child'), '[not(following-sibling::*)]');
    is(&$fn(':last-of-type'), '[position()=last()]');
    is(&$fn(':only-child'),
        '[not(preceding-sibling::* or following-sibling::*)]');
    is(&$fn(':only-of-type'), '[position()=1 and last()=1]');
    is(&$fn(':empty'),
        '[count(*)=0 and (' .
            'count(text())=0 or translate(text()," \t\r\n","")=""' .
        ')]'
    );
    is(&$fn(':checked'), '[@checked]');
    is(&$fn(':disabled'), '[@disabled]');
    is(&$fn(':enabled'), '[not(@disabled)]');

    eval { &$fn('foo') };
    like($@, qr/expected :/i);
    eval { &$fn('::') };
    like($@, qr/expected identifier/i);
    eval { &$fn(':blah-blah') };
    like($@, qr/unknown pseudo/i);
}

# Parse functions
{
    my $fn = sub { Pinwheel::TagSelect::parse_function(Pinwheel::TagSelect::lexer(shift)) };

    is(&$fn('not(a)'), '[not(a)]');
    is(&$fn('nth-child(4)'), '[count(./preceding-sibling::*)=3]');
    is(&$fn('nth-last-child(7)'), '[count(./following-sibling::*)=6]');
    is(&$fn('nth-of-type(4)'), '[position()=4]');
    is(&$fn('nth-last-of-type(4)'), '[last()-position()=3]');
    is(&$fn('first-of-type()'), '[position()=1]');
    is(&$fn('last-of-type()'), '[position()=last()]');
    is(&$fn('only-of-type()'), '[last()=1]');

    eval { &$fn('!') };
    like($@, qr/expected function name/i);
    eval { &$fn('blah-blah') };
    like($@, qr/expected \(/i);
    eval { &$fn('blah-blah(') };
    like($@, qr/unknown function/i);
    eval { &$fn('not(a') };
    like($@, qr/expected \)/i);
    eval { &$fn('nth-child(a)') };
    like($@, qr/expected number/i);
    eval { &$fn('nth-last-child(a)') };
    like($@, qr/expected number/i);
    eval { &$fn('nth-of-type(a)') };
    like($@, qr/expected number/i);
    eval { &$fn('nth-last-of-type(a)') };
    like($@, qr/expected number/i);
}

# Parse selector
{
    my $fn = sub { Pinwheel::TagSelect::parse_selector(Pinwheel::TagSelect::lexer(shift)) };

    is(&$fn('*'), '*');
    is(&$fn('foo-bar'), 'foo-bar');
    is(&$fn('div#blah'), 'div[@id="blah"]');
    is(&$fn('a.b'), 'a[contains(concat(" ",@class," ")," b ")]');
    is(&$fn('a>b'), 'a/b');
    is(&$fn('a b'), 'a//b');
    is(&$fn('a *'), 'a//*');
    is(&$fn('a~b'), 'a/following-sibling::*/self::b');
    is(&$fn('a+b'), 'a/following-sibling::*[1]/self::b');
    is(&$fn('a#b>c'), 'a[@id="b"]/c');
    is(&$fn('a.b>c'), 'a[contains(concat(" ",@class," ")," b ")]/c');
    is(&$fn('a#b c'), 'a[@id="b"]//c');

    is(&$fn('a[b] > c[d]'), 'a[@b]/c[@d]');
    is(&$fn('a[b] c[d]'), 'a[@b]//c[@d]');
    is(&$fn('a[b="c"]'), 'a[@b="c"]');
    is(&$fn('a[b~="c"]'), 'a[contains(concat(" ",@b," ")," c ")]');
    is(&$fn('a[b|="c"]'), 'a[@b="c" or starts-with(@b,"c-")]');

    is(&$fn('a:checked'), 'a[@checked]');

    is(&$fn('a:nth-child(3)'), 'a[count(./preceding-sibling::*)=2]');

    is(&$fn('a#b:checked'), 'a[@id="b"][@checked]');
    is(&$fn('a#b:checked > c'), 'a[@id="b"][@checked]/c');

    # XXX Are all of these correct?
    is(&$fn('a:not(b)'), 'a[not(b)]');
    is(&$fn('a:not(#b)'), 'a[not(@id="b")]');
    is(&$fn('a:not([b])'), 'a[not(@b)]');
    is(&$fn('a:not(b#c)'), 'a[not(b[@id="c"])]');
}

# CSS selector to XPath
{
    my $fn = \&Pinwheel::TagSelect::selector_to_xpath;

    is(&$fn('a'), '//a');
    is(&$fn('a#b'), '//a[@id="b"]');
    is(&$fn('#a'), '//*[@id="a"]');
    is(&$fn('x|a'), '//x:a');
    is(&$fn('foaf|name'), '//foaf:name');

    eval { &$fn('a:not(b))') };
    like($@, qr/unexpected trailing/i);
}
