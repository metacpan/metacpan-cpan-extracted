#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use Test::More; #tests => 1;

use File::Spec;
use File::Temp qw/tempdir/;
use Encode;

use PFT::Text::Symbol;
use PFT::Content;
use PFT::Header;

use Text::Markdown 'markdown';
my $html = markdown(decode('utf-8', join '', <::DATA>));
close ::DATA;

my @syms = PFT::Text::Symbol->scan_html($html);
foreach (@syms) {
    diag "Found ", $_->keyword, '(', join(', ', $_->args), ")\n";
    diag '   at start ', $_->start, ' len ', $_->len, "\n";
    diag "   ", substr($html, $_->start - 10, $_->len + 20) =~ s/\n/\$/rgs, "\n";
    diag "   ", '-' x 10, '^', $_->len > 2 ? ('.' x ($_->len - 2), "^\n") : "\n";
}

do {
    my @snips = map{ '":'.$_->keyword.':'.join('/', $_->args).'"' } @syms;
    my @found = map{ substr($html, $_->start - 1, $_->len + 2) } @syms;
    is_deeply(\@snips, \@found, 'Symbols are Correct');
};

is(scalar @syms, 9, 'Symbols are Complete');

done_testing();

__END__
# Hello there.

This is some random markdown, which is the format used for PFT::Text. It
can contain some weird stuff, like [pft links][lnk], which are just
like [regular links](example.com) except they are [pft links](:truestory:).

Oh, there are also
<img src=":pics:best/kitten.png" alt="pictures"/>
![of any kind](:pics:best/horse.png)
![no, seriously!](:pics:best/goat.png "Oh, a goat!")

    But you can always [explain it on PFT](:like:this)

[lnk]: :foo:bar/baz

<a 
href=":x:">
Multiline links should be supported
</a>

Images as well:
<img
src=":y:a/b/c"/>

And broken stuff, and nested also:
<a href=":w:b"><img src=":z:a">No slash in img!</a>
