#!perl

use Test::More tests => 2;
use lib "./t/lib";

local $ENV{SLEDGE_CONFIG_NAME} = '_common';

use MyApp;
use IO::Scalar;
{
    tie *STDOUT, 'IO::Scalar', \my $s;
    local $ENV{PATH_INFO} = '/';
    local $ENV{REQUEST_URI} = '/';
    local $ENV{HTTP_HOST} = 'localhost';
    MyApp->run;
    like $s, qr/Hello MyApp/;
}

{
    tie *STDOUT, 'IO::Scalar', \my $s;
    local $ENV{PATH_INFO} = '/foo/bar';
    local $ENV{REQUEST_URI} = '/foo/bar';
    local $ENV{HTTP_HOST} = 'localhost';
    MyApp->run;
    like $s, qr{foo/bar};
}



