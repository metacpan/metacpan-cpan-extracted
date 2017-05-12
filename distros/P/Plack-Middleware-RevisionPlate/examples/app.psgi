use strict;
use warnings;

use lib 'lib';
use Plack::Builder;
use Plack::Middleware::RevisionPlate;

# $ carton exec -- plackup example/app.psgi

builder {
    enable 'Plack::Middleware::RevisionPlate',
        path => '/site/sha1', revision_filename => './example/REVISION';

    sub {
        my $env = shift;
        return [ 200, [], ['Hello! Plack'] ];
    };
};

