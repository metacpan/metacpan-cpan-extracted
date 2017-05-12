use strict;
use warnings;
use Test::More;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;

use Plack::App::SourceViewer;

my $app = builder {
    mount "/source" => Plack::App::SourceViewer->new(root => 'share');
    mount '/' => sub { [200, [], ['ok']] };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/source/NotFound.pm');
    is $res->code, 404;
    is $res->content_type, 'text/plain';
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/source/Foo.pm');
    is $res->code, 200;
    is $res->content_type, 'text/html';
    like $res->content, qr!<tr id="L1"><td class="line-count">1</td><td><span class="keyword">package</span>&nbsp;Foo;</td></tr>!;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/source/hoge.html');
    is $res->code, 200;
    is $res->content_type, 'text/html';
    like $res->content, qr!<tr id="L1"><td class="line-count">1</td><td>&lt;div&gt;hoge&amp;fuga&lt;/div&gt;</td></tr>!;
};

done_testing;
