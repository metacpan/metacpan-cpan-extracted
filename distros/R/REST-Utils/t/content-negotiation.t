#!/usr/bin/perl

# Test content negotiation
use strict;
use warnings;
use Test::More tests => 10;
use CGI;
use Test::WWW::Mechanize::CGI;
use REST::Utils qw( media_type );

my $mech = Test::WWW::Mechanize::CGI->new;
$mech->cgi( sub {
    my $q = CGI->new;    

    my $preferred = media_type($q, 
        ['application/xhtml+xml', 'text/html', 'text/plain']);
    if (!defined $preferred) {
        print $q->header(-status => '415 Media Type Unsupported', -type => 'text/plain');
    }
    elsif ($preferred eq q{}) {
        print $q->header(-type => 'text/vrml');
    }
    else {
        print $q->header(-type => $preferred, -charset => q{});
    }
});

$mech->add_header(Accept => 'application/xhtml+xml;q=1.0, text/html;q=0.9, text/plain;q=0.8, */*;q=0.1');

$mech->get('http://localhost/');
is($mech->response->header('content_type'), 'application/xhtml+xml', 'GET preferred content type');

$mech->add_header(Accept => 'application/xhtml+xml;q=0.9, text/html;q=0.8, text/plain;q=1.0, */*;q=0.1');

$mech->get('http://localhost/');
is($mech->content_type, 'text/plain', 'GET preferred content type (not in order)');

$mech->add_header(Accept => 'image/gif;q=1.0');

$mech->get('http://localhost/');
is($mech->status, '415', 'GET preferred content type (unusable media type)');

$mech->add_header(Accept => 'application/xhtml+xml;q=1.0, text/html;q=0.9, text/plain;q=0.8, */*;q=0.1');

$mech->head('http://localhost/');
is($mech->response->header('content_type'), 'application/xhtml+xml', 'HEAD preferred content type');

$mech->post('http://localhost/', content => q{}, Content_Type => 'text/html');
is($mech->content_type, 'text/html', 'POST preferred content type (with Accept)');

$mech->put('http://localhost/', content => q{}, Content_Type => 'text/html');
is($mech->content_type, 'text/html', 'PUT preferred content type (with Accept)');

$mech->post('http://localhost/', Content_Type => 'text/plain');
is($mech->content_type, 'text/plain', 'POST preferred content type (with Content-Type)');

$mech->put('http://localhost/', Content_Type => 'text/plain');
is($mech->content_type, 'text/plain', 'PUT preferred content type (with Content-Type');

$mech->post('http://localhost/', Content_Type => 'text/plain', 'X-HTTP-Method-Override' => 'DELETE');
is($mech->content_type, 'text/vrml', 'no content negotiation with DELETE');

$mech->post('http://localhost/', Content_Type => undef);
is($mech->status, '415', 'no content type');
