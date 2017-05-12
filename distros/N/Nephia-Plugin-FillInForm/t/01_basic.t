use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use URI;
use Nephia::Core;

my $v = Nephia::Core->new(
    plugins => ['FillInForm'],
    app => sub {
        my $path   = req()->path;
        my $params = param()->as_hashref;
        fillin_form($params) unless $path =~ /suppress/;
        [200, [], '<html><body><form id="foo"><input name="name"><input name="message"></form></body></html>'];
    },
);
my $app = $v->run;

test_psgi $app, sub {
    my $cb = shift;
    my $uri = URI->new('/'); 
    $uri->query_form(name => 'ytnobody', message => 'ohayoujo!');
    my $res = $cb->(GET $uri->as_string);
    like $res->content, qr/<input(?: (?:value="ytnobody"|name="name")){2}><input(?: (?:value="ohayoujo!"|name="message")){2}>/;
};

test_psgi $app, sub {
    my $cb = shift;
    my $uri = URI->new('/suppress'); 
    $uri->query_form(name => 'ytnobody', message => 'ohayoujo!');
    my $res = $cb->(GET $uri->as_string);
    like $res->content, qr|<input name="name"><input name="message">|;
};

done_testing;

1;
