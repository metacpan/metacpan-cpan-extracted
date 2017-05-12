use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;

use Plack::Middleware::StackTrace::LinkedSource;

my $source_path;
{
    my $traceapp = Plack::Middleware::StackTrace::LinkedSource->wrap(sub { die "orz" }, no_print_errors => 1);
    my $app = sub {
        my $env = shift;
        my $ret = $traceapp->($env);
        return $ret;
    };
    test_psgi $app, sub {
        my $cb = shift;

        my $req = GET "/";
        $req->header(Accept => "text/html,*/*");
        my $res = $cb->($req);

        ok $res->is_error;
        is_deeply [ $res->content_type ], [ 'text/html', 'charset=utf-8' ];
        like $res->content, qr/<title>Error: orz/;
        like $res->content, qr!<a href="/source/(.+/)?Try/Tiny\.pm\#L\d+">.+[/\\]Try[/\\]Tiny\.pm line \d+</a>!;
        ($source_path) = ($res->content =~ m!<a href="(/source/[^\.]+\.pm)\#L\d+">!);
        ok $source_path and note $source_path;
    }
}

{
    my $sourceapp = Plack::Middleware::StackTrace::LinkedSource->wrap(sub { [200, [], ["OK"]] });
    my $app = sub {
        my $env = shift;
        return $sourceapp->($env);
    };
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET $source_path);
        is $res->code, 200;
        like $res->content, qr!<title>[^\.]+\.pm!;
    }
}

{
    local $ENV{PLACK_ENV} = 'production';
    my $traceapp = Plack::Middleware::StackTrace::LinkedSource->wrap(sub { die "omg" }, no_print_errors => 1);
    my $app = sub {
        my $env = shift;
        my $ret = $traceapp->($env);
        return $ret;
    };
    test_psgi $app, sub {
        my $cb = shift;

        my $req = GET "/";
        my $res = $cb->($req);

        ok $res->is_error;
        is $res->content_type, 'text/plain';
        like $res->content, qr/omg at/;
        unlike $res->content, qr/>omg/;
    }
}

{
    local $ENV{PLACK_ENV} = 'production';
    my $traceapp = Plack::Middleware::StackTrace::LinkedSource->wrap(sub { die "amg" }, no_print_errors => 1, force => 1);
    my $app = sub {
        my $env = shift;
        my $ret = $traceapp->($env);
        return $ret;
    };
    test_psgi $app, sub {
        my $cb = shift;

        my $req = GET "/";
        $req->header(Accept => "text/html,*/*");
        my $res = $cb->($req);

        ok $res->is_error;
        is_deeply [ $res->content_type ], [ 'text/html', 'charset=utf-8' ];
        like $res->content, qr/<title>Error: amg/;
        like $res->content, qr!<a href="/source/(.+/)?Try/Tiny\.pm\#L\d+">.+[/\\]Try[/\\]Tiny\.pm line \d+</a>!;
    }
}

my $other_source_path;
{
    my $traceapp = Plack::Middleware::StackTrace::LinkedSource->wrap(sub { die "orz" }, no_print_errors => 1, view_root => '/view_source');
    my $app = sub {
        my $env = shift;
        my $ret = $traceapp->($env);
        return $ret;
    };
    test_psgi $app, sub {
        my $cb = shift;

        my $req = GET "/";
        $req->header(Accept => "text/html,*/*");
        my $res = $cb->($req);

        ok $res->is_error;
        is_deeply [ $res->content_type ], [ 'text/html', 'charset=utf-8' ];
        like $res->content, qr/<title>Error: orz/;
        like $res->content, qr!<a href="/view_source/(.+/)?Try/Tiny\.pm\#L\d+">.+[/\\]Try[/\\]Tiny\.pm line \d+</a>!;
        ($other_source_path) = ($res->content =~ m!<a href="(/view_source/[^\.]+\.pm)\#L\d+">!);
        ok $other_source_path and note $other_source_path;
    }
}

{
    my $sourceapp = Plack::Middleware::StackTrace::LinkedSource->wrap(sub { [200, [], ["OK"]] }, view_root => '/view_source');
    my $app = sub {
        my $env = shift;
        return $sourceapp->($env);
    };
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET $other_source_path);
        is $res->code, 200;
        like $res->content, qr!<title>[^\.]+\.pm!;
    }
}

done_testing;
