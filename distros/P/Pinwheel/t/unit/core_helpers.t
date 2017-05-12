#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

use Pinwheel::Helpers::Core qw(content_for yield urlencode urldecode);
use Pinwheel::View::String;


# Content blocks
{
    my $yield;

    $yield = sub { my $s = yield(@_); "$s" };

    content_for('header', sub { '123' });
    content_for('layout', sub { 'abc' });
    content_for('layout', sub { 'def' });
    content_for('css', sub { Pinwheel::View::String->new('<br />') });

    is(&$yield(), 'abcdef');
    is(&$yield('layout'), 'abcdef');
    is(&$yield('header'), '123');
    is(&$yield('css'), '<br />');
}

# URL encoding/decoding
{
    is(urlencode(' + '), '%20%2B%20');
    is(urlencode('&?&'), '%26%3F%26');
    is(urlencode('eée'), 'e%8Ee');

    is(urldecode('%20%2B%20'), ' + ');
    is(urldecode('%26%3F%26'), '&?&');
    is(urldecode('e%8Ee'), 'eée');
}

