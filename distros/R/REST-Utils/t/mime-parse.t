#!/usr/bin/perl

# Test MIME parsing functions.
# 1st 24 tests taken from MIMEParse.pm byJoe Gregorio <joe@bitworking.org>
# and Stanis Trendelenburg <stanis.trendelenburg@gmail.com>
# (http://code.google.com/p/mimeparse/)
use strict;
use warnings;
use Test::More tests => 27;
use REST::Utils qw( parse_media_range quality best_match fitness_and_quality_parsed);

is_deeply( [parse_media_range('application/xml;q=1')],
    ['application', 'xml', { q => 1 }] );
is_deeply( [parse_media_range('application/xml')],
    ['application', 'xml', { q => 1 }] );
is_deeply( [parse_media_range('application/xml;q=')],
    ['application', 'xml', { q => 1 }] );
is_deeply( [parse_media_range('application/xml ; q=')],
    ['application', 'xml', { q => 1 }] );
is_deeply( [parse_media_range('application/xml ; q=1;b=other')],
    ['application', 'xml', { q => 1, b => 'other' }] );
is_deeply( [parse_media_range('application/xml ; q=2;b=other')],
    ['application', 'xml', { q => 1, b => 'other' }] );

# Java URLConnection class sends an Accept header that includes a single *
is_deeply( [parse_media_range(" *; q=.2")], ['*', '*', { q => '.2' }] );

# example from rfc 2616
my $accept = "text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5";
is( quality("text/html;level=1", $accept), 1   );
is( quality("text/html",         $accept), 0.7 );
is( quality("text/plain",        $accept), 0.3 );
is( quality("image/jpeg",        $accept), 0.5 );
is( quality("text/html;level=2", $accept), 0.4 );
is( quality("text/html;level=3", $accept), 0.7 );

my $mime_types_supported = ['application/xbel+xml', 'application/xml'];
is( best_match($mime_types_supported, 'application/xbel+xml'),
    'application/xbel+xml', "direct match" );
is( best_match($mime_types_supported, 'application/xbel+xml; q=1'),
    'application/xbel+xml', "direct match with a q parameter" );
is( best_match($mime_types_supported, 'application/xml; q=1'),
    'application/xml', "direct match of our second choice with a q parameter" );
is( best_match($mime_types_supported, 'application/*; q=1'),
    'application/xml', "match using a subtype wildcard" );
is( best_match($mime_types_supported, '*/*'),
    'application/xml', "match using a type wildcard" );

$mime_types_supported = ['application/xbel+xml', 'text/xml'];
is( best_match($mime_types_supported, 'text/*;q=0.5,*/*; q=0.1'),
    'text/xml', "match using a type versus a lower weighted subtype" );
is( best_match($mime_types_supported, 'text/html,application/atom+xml; q=0.9'),
    undef, "fail to match anything" );

$mime_types_supported = ['application/json', 'text/html'];
is( best_match($mime_types_supported, 'application/json, text/javascript, */*'),
    'application/json', "common AJAX scenario" );
is( best_match($mime_types_supported, 'application/json, text/html;q=0.9'),
    'application/json', "verify fitness ordering" );

$mime_types_supported = ['image/*', 'application/xml'];
is( best_match($mime_types_supported, 'image/png'),
    'image/*', "match using a type wildcard" );
is( best_match($mime_types_supported, 'image/*'),
    'image/*', "match using a wildcard for both requested and supported " );

is_deeply( [parse_media_range('application/xhtml;q=a')],
    ['application', 'xhtml', { q => 1 }] );

is_deeply( [parse_media_range('application/xhtml;q=-1')],
    ['application', 'xhtml', { q => 1 }] );

is_deeply( [fitness_and_quality_parsed('*/gif', [ 'text/html' ] )], [-1, 0] );
