#!/usr/bin/perl

# Test HTTP tunneling
use strict;
use warnings;
use Test::More tests => 26;
use CGI;
use Test::WWW::Mechanize::CGI;
use REST::Utils qw( request_method );

my $mech = Test::WWW::Mechanize::CGI->new;
$mech->cgi( sub {
    my $q = CGI->new;    
    if ($q->param('empty_req') || $q->url_param('empty_req')) {
           delete $ENV{REQUEST_METHOD};
    }
    my $method = request_method($q);

    print $q->header,
        $q->start_html($method || 'empty'),
        $q->end_html;
});

$mech->post('http://localhost/', { _method => 'DELETE'});
$mech->title_is('DELETE', 'tunnel DELETE via POST (query param)');

$mech->post('http://localhost/', { _method => 'GET'});
$mech->title_is('GET', 'tunnel GET via POST (query param)');

$mech->post('http://localhost/', { _method => 'HEAD'});
$mech->title_is('HEAD', 'tunnel HEAD via POST (query param)');

$mech->post('http://localhost/', { _method => 'POST'});
$mech->title_is('POST', 'tunnel POST via POST (query param)');

$mech->post('http://localhost/', { _method => 'PUT'});
$mech->title_is('PUT', 'tunnel PUT via POST (query param)');

$mech->post('http://localhost/?_method=DELETE');
$mech->title_is('DELETE', 'tunnel DELETE via POST (url param)');

$mech->post('http://localhost/?_method=GET');
$mech->title_is('GET', 'tunnel GET via POST (url param)');

$mech->post('http://localhost/?_method=HEAD');
$mech->title_is('HEAD', 'tunnel HEAD via POST (url param)');

$mech->post('http://localhost/?_method=POST');
$mech->title_is('POST', 'tunnel POST via POST (url param)');

$mech->post('http://localhost/?_method=PUT');
$mech->title_is('PUT', 'tunnel PUT via POST (url param)');

$mech->get('http://localhost/?_method=DELETE');
$mech->title_is('GET', 'cannot tunnel DELETE via GET (query param)');

$mech->get('http://localhost/?_method=GET');
$mech->title_is('GET', 'tunnel GET via GET (query param)');

$mech->get('http://localhost/?_method=HEAD');
$mech->title_is('HEAD', 'tunnel HEAD via GET (query param)');

$mech->get('http://localhost/?_method=POST');
$mech->title_is('GET', 'cannot tunnel POST via GET (query param)');

$mech->get('http://localhost/?_method=PUT');
$mech->title_is('GET', 'cannot tunnel PUT via GET (query param)');

$mech->add_header('X-HTTP-Method-Override' => 'DELETE');
$mech->post('http://localhost/');
$mech->title_is('DELETE', 'tunnel DELETE via POST (http header)');

$mech->add_header('X-HTTP-Method-Override' => 'GET');
$mech->post('http://localhost/');
$mech->title_is('GET', 'tunnel GET via POST (http header)');

$mech->add_header('X-HTTP-Method-Override' => 'HEAD');
$mech->post('http://localhost/');
$mech->title_is('HEAD', 'tunnel HEAD via POST (http header)');

$mech->add_header('X-HTTP-Method-Override' => 'POST');
$mech->post('http://localhost/');
$mech->title_is('POST', 'tunnel POST via POST (http header)');

$mech->add_header('X-HTTP-Method-Override' => 'PUT');
$mech->post('http://localhost/');
$mech->title_is('PUT', 'tunnel PUT via POST (http header)');

$mech->add_header('X-HTTP-Method-Override' => 'DELETE');
$mech->get('http://localhost/');
$mech->title_is('GET', 'cannot tunnel DELETE via GET (http header)');

$mech->add_header('X-HTTP-Method-Override' => 'GET');
$mech->get('http://localhost/');
$mech->title_is('GET', 'tunnel GET via GET (http header)');

$mech->add_header('X-HTTP-Method-Override' => 'HEAD');
$mech->get('http://localhost/');
$mech->title_is('HEAD', 'tunnel HEAD via GET (http header)');

$mech->add_header('X-HTTP-Method-Override' => 'POST');
$mech->get('http://localhost/');
$mech->title_is('GET', 'cannot tunnel POST via GET (http header)');

$mech->add_header('X-HTTP-Method-Override' => 'PUT');
$mech->get('http://localhost/');
$mech->title_is('GET', 'cannot tunnel PUT via GET (http header)');

$mech->post('http://localhost/', {empty_req => 'DEMAND'});
$mech->title_is('empty', 'empty request method');
