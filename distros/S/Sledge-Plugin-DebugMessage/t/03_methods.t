use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use Sledge::TestPages";
    plan $@ ? (skip_all => 'needs Sledge::TestPages for testing') : (tests => 7);
}

package Mock::Pages;
use base qw(Sledge::TestPages);
use Sledge::Plugin::DebugMessage;

sub debug_level { 1 }

sub dispatch_foo {
    my $self = shift;
    $self->debug('foo' => 'bar');
}

__PACKAGE__->add_trigger(BEFORE_DISPATCH => sub {
    my $self = shift;
    $self->debug('mmm' => 'iyan');
});

package main;
my $d = $Mock::Pages::TMPL_PATH;
$Mock::Pages::TMPL_PATH = 't/tmpl';
my $c = $Mock::Pages::COOKIE_NAME;
$Mock::Pages::COOKIE_NAME = 'sid';
$ENV{HTTP_COOKIE}    = "sid=SIDSIDSIDSID";
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'aff_type=mock&s=ABCDEFG';

my $page = Mock::Pages->new;
$page->dispatch('foo');

like $page->output, qr(foo : \$VAR1 = 'bar'), 'debug message';
like $page->output, qr{<tr><th>r</th><td>Sledge::Request::CGI=HASH\([^)]+\)</td></tr>}, 'tmpl';
like $page->output, qr{<tr><th>session</th><td>Sledge::TestSession=HASH\([^)]+\)</td></tr>}, 'tmpl(2)';
like $page->output, qr{<tr><th>config</th><td>Sledge::TestConfig=HASH\([^)]+\)</td></tr>}, 'tmpl(3)';
like $page->output, qr{<tr><th>aff_type</th><td>mock</td></tr>}, 'r';
like $page->output, qr{<tr><th>s</th><td>ABCDEFG</td></tr>}, 'r(2)';
like $page->output, qr{<tr><th>_timestamp</th><td>\d+</td></tr>}, 'session';

