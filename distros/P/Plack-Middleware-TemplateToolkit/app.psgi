#!/usr/bin/env perl

# This app.psgi is for testing slightly more complex configurations

use strict;
use warnings;
use lib qw(lib);

use Plack::Builder;
use File::Spec;
use File::Basename;
use Cwd;

my $root = Cwd::realpath( File::Spec->catdir( dirname($0), "t","root") );

my $app = sub { [ 500, ["Content-type"=>"text/plain"], ["Server hit the bottom"] ] };

builder {

    # Page to show when requested file is missing
    enable "Plack::Middleware::ErrorDocument",
        404 => "$root/404.html";

    # These files can be served directly
    enable "Plack::Middleware::Static",
        path => qr{\.[gif|png|jpg|swf|ico|mov|mp3|pdf|js|css]$},
        root => $root;

    # Templates
    enable "Plack::Middleware::Template",
        INCLUDE_PATH => $root;

    $app;
}

