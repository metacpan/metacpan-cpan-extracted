use strict;
use Test::More 'no_plan';

use CGI;
use IO::Scalar;
use Sledge::Request::CGI;

package Mock::Pages;
use base qw(Sledge::Pages::CGI);
use Sledge::Plugin::Private 'POST';

package main;
$ENV{REQUEST_METHOD} = 'POST';
my $r = Sledge::Request::CGI->new(CGI->new({}));
my $page = bless { r => $r }, 'Mock::Pages';
$page->invoke_hook('AFTER_INIT');

tie *STDOUT, 'IO::Scalar', \my $out;
$page->r->send_http_header;
untie *STDOUT;

like $out, qr/Cache-Control: private/;
