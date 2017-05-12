use strict;
use warnings;

package Test;

use Test::More tests => 9;

use Template::Caribou::Tags::HTML::Extended ':all';

use Template::Caribou;

has '+indent' => default => 0;

local *::RAW;
open ::RAW, '>', \my $raw;

is do {
    doctype 'html5'
} => "<!DOCTYPE html>\n", 'doctype';

is do { favicon "foo" } => '<link href="foo" rel="shortcut icon" />', 'favicon';

my $bou = Test->new;

sub render_ok(&$$) {
    my ( $template, $expected, $title) = @_;
    is $bou->render($template), $expected, $title;
}

render_ok sub { submit "foo", id => 'bar'; } 
    => '<input id="bar" type="submit" value="foo" />', 'submit';

render_ok sub { css "X" } 
    => '<style type="text/css">X</style>', 'css';

subtest anchor => sub {
    render_ok sub { anchor "http://foo.com" => 'linkie' }
        => '<a href="http://foo.com">linkie</a>', 'anchor';

    render_ok sub { anchor "http://foo.com" => sub {
        print ::RAW "this <b>thing</b>";
    } } => '<a href="http://foo.com">this <b>thing</b></a>', 'anchor';


    # for when anchors are URIs...
    package Foo { use overload '""' => sub { $_[0][0] }; }

    my $foo = ['potato'];
    bless $foo, 'Foo';

    render_ok sub { anchor $foo => 'this' } => '<a href="potato">this</a>', 'when anchors are refs';

};

render_ok sub { image "/foo.jpg" } => '<img src="/foo.jpg" />', 'image';

render_ok sub { markdown "this is *awesome*" } => "<p>this is <em>awesome</em></p>\n", 'markdown';

render_ok sub {
    css_include 'foo/bar.css';
}, '<link href="foo/bar.css" rel="stylesheet" />', 'css_include';

render_ok sub {
    css_include 'foo/bar.css', media => 'screen';
}, '<link href="foo/bar.css" media="screen" rel="stylesheet" />', 'css_include with arguments';

