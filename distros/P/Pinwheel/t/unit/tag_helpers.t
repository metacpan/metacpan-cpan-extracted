#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 39;

use Pinwheel::Helpers::Tag qw(content_tag link_to link_to_if link_to_unless link_to_unless_current);
use Pinwheel::View::String;

use Pinwheel::DocTest;


sub escape
{
    my $s = shift;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}


# Generate content tags
{
    my ($base, $ct, $fn, $s);

    $base = Pinwheel::View::String->new('', \&escape);
    $ct = sub { ($base . content_tag(@_))->to_string() };

    is(&$ct('x'), "<x />\n");
    is(&$ct('x', 'y'), "<x>y</x>\n");
    is(&$ct('x', 'y&z'), "<x>y&amp;z</x>\n");
    is(&$ct('x', a => 'b'), "<x a=\"b\" />\n");
    is(&$ct('x', 'foo', c => 'd'), "<x c=\"d\">foo</x>\n");

    is(&$ct('img', src => 'a&b'), "<img src=\"a&amp;b\" />\n");

    is(&$ct('x', a => undef, b => 'c'), "<x b=\"c\" />\n");

    is(&$ct('x', a => 'b', c => 'd'), "<x a=\"b\" c=\"d\" />\n");
    is(&$ct('x', c => 'd', a => 'b'), "<x c=\"d\" a=\"b\" />\n");

    $fn = sub { 'blah' };
    is(&$ct('x', $fn), "<x>blah</x>\n");
    $fn = sub { 'blah < foo' };
    is(&$ct('x', $fn), "<x>blah < foo</x>\n");

    is(&$ct('x', a => ['b', 'c']), "<x a=\"b c\" />\n");
    is(&$ct('x', a => []), "<x />\n");
    is(&$ct('x', a => [undef]), "<x />\n");
    is(&$ct('x', a => ['']), "<x />\n");
    is(&$ct('x', a => ['', 'b']), "<x a=\"b\" />\n");
    is(&$ct('x', a => [undef, 'b']), "<x a=\"b\" />\n");
    is(&$ct('x', a => ['0', 'b', '', 'c']), "<x a=\"0 b c\" />\n");
    is(&$ct('x', a => [undef, 'b', undef, 'c']), "<x a=\"b c\" />\n");

    $s = content_tag('em', 'a & b');
    $s = content_tag('a', $s, href => 'foo');
    $s = ($base . $s)->to_string();
    is($s, "<a href=\"foo\"><em>a &amp; b</em>\n</a>\n");
}



# Generate hyperlink tags
{
    my $link;

    $Pinwheel::Controller::map->reset();
    Pinwheel::Controller::connect('r', '/:network/p/:brand');
    Pinwheel::Controller::connect('s', '/:foo/x');
    Pinwheel::Controller::connect('t', 'http://foo.com/*path');


    $link = link_to('content', 't', {path => 'rabbits'});
    is("$link", "<a href=\"http://foo.com/rabbits\">content</a>\n");

    $link = link_to('content', 't', {path => 'a'}, class => 'b');
    is("$link", "<a href=\"http://foo.com/a\" class=\"b\">content</a>\n");

    $link = link_to('content', 't', {path => 'a'}, class => [ 'b', 'c' ]);
    is("$link", "<a href=\"http://foo.com/a\" class=\"b c\">content</a>\n");

    $link = link_to('content', 's', {foo => 'bar'});
    is("$link", "<a href=\"/bar/x\">content</a>\n");

    $link = link_to('Scott Mills', 'r', {network => 'radio1', brand => 'scottmills'});
    is("$link", "<a href=\"/radio1/p/scottmills\">Scott Mills</a>\n");

    $link = link_to('Scott Mills', 'http://www.scottmills.co.uk/');
    is("$link", "<a href=\"http://www.scottmills.co.uk/\">Scott Mills</a>\n");

    $link = link_to("blah", "/something.html");
    is("$link", "<a href=\"/something.html\">blah</a>\n");


    ## link_to_if
    $link = link_to_if(1, "blah", "/something.html");
    is("$link", "<a href=\"/something.html\">blah</a>\n");

    $link = link_to_if(1, "blah", "/something.html", class => 'bold');
    is("$link", "<a href=\"/something.html\" class=\"bold\">blah</a>\n");

    $link = link_to_if(0, "blah", "/something.html");
    is("$link", "blah");


    ## link_to_unless
    $link = link_to_unless(0, 'content', 's', {foo => 'bar'});
    is("$link", "<a href=\"/bar/x\">content</a>\n");

    $link = link_to_unless(0, 'content', 's', {foo => 'bar'}, class => 'bold');
    is("$link", "<a href=\"/bar/x\" class=\"bold\">content</a>\n");

    $link = link_to_unless(1, 'content', 's', {foo => 'bar'});
    is("$link", "content");
}


## link_to_unless_current
{
    my $link;

    # Mock out the url_for() method
    my $mock_url_for = Pinwheel::DocTest::Mock->new('url_for');
    $mock_url_for->returns(sub {
        my ($name, %params) = @_;
        return "/$name/" . join('/', values %params) . '.html' if (%params);
        return '/something.html'
    });
    no warnings 'redefine';
    local *Pinwheel::Controller::url_for = \&$mock_url_for;

    $link = link_to_unless_current("blah", "/something.html");
    is("$link", "blah");

    $link = link_to_unless_current("blah", "/nothing.html");
    is("$link", "<a href=\"/nothing.html\">blah</a>\n");

    $link = link_to_unless_current("blah", "/nothing.html", class => 'bold');
    is("$link", "<a href=\"/nothing.html\" class=\"bold\">blah</a>\n");

    $link = link_to_unless_current('content', 'nothing', {path => 'rabbits'});
    is("$link", "<a href=\"/nothing/rabbits.html\">content</a>\n");

    $link = link_to_unless_current('content', 'nothing', {path => 'rabbits'}, class => 'bold');
    is("$link", "<a href=\"/nothing/rabbits.html\" class=\"bold\">content</a>\n");

    $link = link_to_unless_current('content', 'something', {});
    is("$link", "content");
}
