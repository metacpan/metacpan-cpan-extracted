package MyApp::Controller::Web::Auth;

use strict;
use warnings;
use parent 'Punk::Controller';

sub required {
    my ($c) = @_;
    return if ($c->req->header('authorization') // '') eq 'let-me-in';
    return $c->json({ errors => [ { message => 'unauthorized' } ] }, 401);
}

1;
