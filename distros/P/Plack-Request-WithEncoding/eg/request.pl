#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Request::WithEncoding;

my $app_or_middleware = sub {
    my $env = shift; # PSGI env

    # Example of $env
    #
    # $env = {
    #     QUERY_STRING   => 'query=%82%d9%82%b0', # <= encoded by 'cp932'
    #     REQUEST_METHOD => 'GET',
    #     HTTP_HOST      => 'example.com',
    #     PATH_INFO      => '/foo/bar',
    # };

    my $req = Plack::Request::WithEncoding->new($env);
    $req->env->{'plack.request.withencoding.encoding'} = 'cp932'; # <= specify the encoding method.

    my $query = $req->param('query'); # <= get parameters of 'query' that is decoded by 'cp932'.

    my $res = $req->new_response(200); # new Plack::Response
    $res->finalize;
};
