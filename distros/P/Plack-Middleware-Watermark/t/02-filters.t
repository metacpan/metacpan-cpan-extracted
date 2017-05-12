#!/usr/bin/env perl
use strict;
use warnings;

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;

sub test_app {
    my ($content_type) = @_;
    my $app = sub {
        return [
            200,
            [ 'Content-Type' => $content_type ],
            [ 'Hello!!' ],
        ];
    };
    builder {
        enable 'Watermark', 'comment' => 'TEST';
        $app;
    };
}

{
    ## html/xml
    my @content_types = (
        'text/html',
        'text/xml',
        'text/html; charset=utf8',
        'application/xhtml+xml; chatset=utf8',
        'application/xml',
        'application/atom+xml',
        'application/rss+xml',
    );
    for my $content_type (@content_types) {
        my $app = test_app($content_type);
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');
            is $res->content, qq{Hello!!<\!-- TEST -->};
        };
    }
}

{
    ## javascript
    my @content_types = (
        'text/javascript',
        'application/javascript',
    );
    for my $content_type (@content_types) {
        my $app = test_app($content_type);
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');
            is $res->content, qq{Hello!!// TEST };
        };
    }
}

{
    ## css
    my @content_types = (
        'text/css',
    );
    for my $content_type (@content_types) {
        my $app = test_app($content_type);
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');
            is $res->content, qq{Hello!!/* TEST */};
        };
    }
}

{
    ## others
    my @content_types = (
        'text/plain',
    );
    for my $content_type (@content_types) {
        my $app = test_app($content_type);
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');
            is $res->content, qq{Hello!!};
        };
    }
}

done_testing;
