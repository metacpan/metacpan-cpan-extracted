#!/usr/bin/perl

# Test retrieval of HTTP request body.
use strict;
use warnings;
use Test::More tests => 10;
use Test::WWW::Mechanize::CGI;
use REST::Utils qw( get_body );

my $mech = Test::WWW::Mechanize::CGI->new;
$mech->cgi( sub {
    require CGI;    
    my $q = CGI->new;    

    my $content = get_body($q);

    output($q, $content);
});

my $mech2 = Test::WWW::Mechanize::CGI->new;
$mech2->cgi( sub {

    require CGI;    
    $CGI::POST_MAX = 10;
    my $q = CGI->new;    

    my $content = get_body($q);

    output($q, $content);
});

sub output {
    my ($q, $content) = @_;

    my $title = q{};
    my $content_length = defined $content ? length $content : 0;

    if (!defined $content) {
        $title = 'Content too big';
    }
    elsif ($content_length == 0) {
        $title = 'No content';
    }
    else {
        $title = $content_length;
    }
    
    print $q->header,
        $q->start_html($title),
        $q->end_html;

    return;
}

$mech->post('http://localhost/');
$mech->title_is('No content', 'POST with no content body');

$mech->put('http://localhost/');
$mech->title_is('No content', 'PUT with no content body');

$mech->get('http://localhost/');
$mech->title_is('No content', 'GET with no content body');

$mech->post('http://localhost/', content_type => 'text/plain',
    content => 'x' x 100);
$mech->title_is('100', 'POST with content body');

$mech->put('http://localhost/', content_type => 'text/plain',
    content => 'x' x 100);
$mech->title_is('100', 'PUT with content body');

$mech->get('http://localhost/', content_type => 'text/plain',
    content => 'x' x 50000);
$mech->title_is('50000', 'GET with large content body');

$mech2->post('http://localhost/', content_type => 'text/plain',
    content => 'x' x 100);
$mech2->title_is('Content too big', 'POST with content_length > POST_MAX');

$mech2->post('http://localhost/', content_type => 'text/plain',
    content => 'x' x 10);
$mech2->title_is('10', 'POST with content_length < POST_MAX');

$mech->get('http://localhost/', content_type => 'text/plain',
    content => 'x' x 10, content_length => 5000);
$mech->title_is('Content too big', 'bogus content length (too big)');

$mech2->add_header( Content_Length => undef );
$mech2->get('http://localhost/', content_type => 'text/plain',
    content => 'x' x 10);
$mech2->title_is('No content', 'missing content length');
