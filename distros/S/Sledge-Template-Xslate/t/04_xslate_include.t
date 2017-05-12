use strict;
use Test::More tests => 2;

use lib 't/lib';

package Mock::Pages;
use parent qw(Sledge::TestPages);
use Sledge::Template::Xslate ({
  syntax => 'TTerse',
  module => ['Text::Xslate::Bridge::TT2Like'],
});

our $TMPL_PATH = "t/template";
our $CACHE_DIR = "t/cache";

sub dispatch_include1 {}

package main;

$ENV{HTTP_HOST}      = "localhost";
$ENV{REQUEST_URI}    = "http://localhost/include1.cgi";
$ENV{REQUEST_METHOD} = 'GET';

my $page = Mock::Pages->new;
$page->dispatch('include1');

my $out = $page->output;
like $out, qr/include1/, $out;
like $out, qr/include2/, $out;
