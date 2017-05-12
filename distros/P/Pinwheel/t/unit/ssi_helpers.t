#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 23;

use Pinwheel::Helpers::SSI qw(
    ssi_if_exists
    ssi_if_not_exists
    ssi_include
    ssi_set
);


$Pinwheel::Controller::map->reset();
Pinwheel::Controller::connect('r', '/:network/p/:brand');
Pinwheel::Controller::connect('s', '/:foo/x');
Pinwheel::Controller::connect('t', 'http://foo.com/*path');

sub escape
{
    my ($s) = @_;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}


# Test SSI includes
{
    my ($include);

    $include = sub { my $s = ssi_include(@_); "$s" };

    is(&$include('filename.ssi'), '<!--#include virtual="filename.ssi" -->');
    is(&$include('../dir/filename.ssi'), '<!--#include virtual="../dir/filename.ssi" -->');
    is(&$include('s', foo => 'a'), '<!--#include virtual="/a/x" -->');
    is(&$include('r', network => 'radio1', brand => 'scottmills'), '<!--#include virtual="/radio1/p/scottmills" -->');
};


# Test SSI defines
{
    my ($key, $value, $s);

    $s = ssi_set('a', 'b');
    is("$s", '<!--#set var="a" value="b" -->');
    $s = ssi_set('foobar', '$foo$bar');
    is("$s", '<!--#set var="foobar" value="$foo$bar" -->');

    $key = Pinwheel::View::String->new('&');
    $value = Pinwheel::View::String->new('<>');
    $s = Pinwheel::View::String->new('', \&escape) . ssi_set($key, $value);
    is("$s", '<!--#set var="&" value="<>" -->');
    $s = Pinwheel::View::String->new('', \&escape) . ssi_set('&', '<>');
    is("$s", '<!--#set var="&amp;" value="&lt;&gt;" -->');
};


# Test SSI if/not exists
{
    my ($base, $ssi);

    $base = Pinwheel::View::String->new('', \&escape);

    $ssi = $base . ssi_if_exists('filename', sub { '<p>yes</p>' });
    like("$ssi", qr/virtual="filename"/, "filename is set");
    like("$ssi", qr/<p>yes<\/p>/, "contents is set");
    like("$ssi", qr/ != /, "compare is correctly is set");

    $ssi = $base . ssi_if_not_exists('filename', sub { '<p>no</p>' });
    like("$ssi", qr/virtual="filename"/, "filename is set");
    like("$ssi", qr/<p>no<\/p>/, "contents is set");
    like("$ssi", qr/ = /, "compare is correctly is set");

    $ssi = $base . ssi_if_exists('s', foo => 'dir', sub { '<p>yes</p>' });
    like("$ssi", qr/virtual="\/dir\/x"/, "filename is set");
    like("$ssi", qr/<p>yes<\/p>/, "contents is set");
    like("$ssi", qr/ != /, "compare is correctly is set");

    $ssi = $base . ssi_if_not_exists('s', foo => 'dir', sub { '<p>no</p>' });
    like("$ssi", qr/virtual="\/dir\/x"/, "filename is set");
    like("$ssi", qr/<p>no<\/p>/, "contents is set");
    like("$ssi", qr/ = /, "compare is correctly is set");
};


# ssi_flastmod utility function
{
    my ($flastmod, $base, $s, $y, $n);

    $flastmod = \&Pinwheel::Helpers::SSI::ssi_flastmod;
    $base = Pinwheel::View::String->new('', \&escape);

    $s = $flastmod->('/path', '=', "<p>yes</p>\n");
    is("$s", <<'EOF');
<!--#func var="file" func="flastmod" virtual="/path" -->
<!--#if expr="(${file} = /\(none\)/)" -->
<p>yes</p>
<!--#endif -->
EOF

    $s = $flastmod->('/path', '=', "<p>yes</p>\n", "<p>no</p>\n");
    is("$s", <<'EOF');
<!--#func var="file" func="flastmod" virtual="/path" -->
<!--#if expr="(${file} = /\(none\)/)" -->
<p>yes</p>
<!--#else -->
<p>no</p>
<!--#endif -->
EOF

    $y = Pinwheel::View::String->new("<yes>\n");
    $n = Pinwheel::View::String->new("<no>\n");
    $s = $base . $flastmod->('/path', '=', $y, $n);
    is("$s", <<'EOF');
<!--#func var="file" func="flastmod" virtual="/path" -->
<!--#if expr="(${file} = /\(none\)/)" -->
<yes>
<!--#else -->
<no>
<!--#endif -->
EOF
}
