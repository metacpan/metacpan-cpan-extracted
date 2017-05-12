use strict;
use warnings;
use Test::More 0.88;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;
use File::Spec;
use File::Basename;

my $base = dirname(File::Spec->rel2abs(__FILE__));

my $handler = builder {
    enable 'Plack::Middleware::Static::Range',
        path => sub { s!^/share/!!}, root => $base;
    mount '/' => builder {
        sub {
            [200, [], ['ok']]
        };
    };
};
my %test = (
    client => sub {
        my $cb  = shift;
        {
            note('not static');
            my $res = $cb->(GET 'http://localhost/');
            is $res->content, 'ok';
        }

        {
            note('entire file');
            my $res = $cb->(GET 'http://localhost/share/foo.txt');
            is $res->content_type, 'text/plain';
            is $res->content, "0123\n5678\n";
        }

        {
            note('first byte');
            my $res = $cb->(GET 'http://localhost/share/foo.txt', Range => 'bytes=0-0');
            is $res->content_type, 'text/plain';
            is $res->content, "0";
        }

        {
            note('first five bytes');
            my $res = $cb->(GET 'http://localhost/share/foo.txt', Range => 'bytes=0-4');
            is $res->content_type, 'text/plain';
            is $res->content, "0123\n";
        }

        {
            note('all but the first five bytes');
            my $res = $cb->(GET 'http://localhost/share/foo.txt', Range => 'bytes=5-');
            is $res->content_type, 'text/plain';
            is $res->content, "5678\n";
        }

        {
            note('next five bytes');
            my $res = $cb->(GET 'http://localhost/share/foo.txt', Range => 'bytes=5-9');
            is $res->content_type, 'text/plain';
            is $res->content, "5678\n";
        }

        {
            note('last five bytes');
            my $res = $cb->(GET 'http://localhost/share/foo.txt', Range => 'bytes=-5');
            is $res->content_type, 'text/plain';
            is $res->content, "5678\n";
        }

        {
            note('last byte');
            my $res = $cb->(GET 'http://localhost/share/foo.txt', Range => 'bytes=-1');
            is $res->content_type, 'text/plain';
            is $res->content, "\n";
        }

        {
            note('4th and last byte');
            my $res = $cb->(GET 'http://localhost/share/foo.txt', Range => 'bytes=4-4,-1');
            is $res->content_type, 'multipart/byteranges';
            my @parts = $res->parts;
            is 0+@parts, 2, "Two byterange parts";
            for (@parts) {
                is $_->content_type, "text/plain";
                is $_->content, "\n";
            }
        }

        {
            note('not 200');
            my $res = $cb->(GET 'http://localhost/share/not_found.css');
            is $res->code, 404;
        }
    },
    app => $handler,
);

test_psgi %test;

done_testing;
