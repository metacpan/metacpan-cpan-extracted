use strict;
use Test::More tests => 5;

use lib 't/lib';

package Mock::Pages;
use parent qw(Sledge::TestPages);
use Sledge::Template::Xslate ({
  syntax => 'TTerse',
  module => ['Text::Xslate::Bridge::TT2Like'],
});

our $TMPL_PATH = "t/template";
our $CACHE_DIR = "t/cache";

sub dispatch_name {
    my $self = shift;
    $self->session->param(var => 'value');
    ::isa_ok $self->tmpl->param('session'), 'Sledge::Session';
    ::isa_ok $self->tmpl->param('r'), 'Sledge::Request::CGI';
    ::isa_ok $self->tmpl->param('config'), 'Sledge::TestConfig';
}

package main;

$ENV{HTTP_HOST}      = "localhost";
$ENV{REQUEST_URI}    = "http://localhost/name.cgi";
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'name=miyagawa';

my $page = Mock::Pages->new;
$page->dispatch('name');

my $out = $page->output;
like $out, qr/name is miyagawa/;
like $out, qr/session var is value/;
