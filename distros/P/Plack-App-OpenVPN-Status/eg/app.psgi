#!/usr/bin/env perl

use strict;
use FindBin ();
use Plack::Builder;
use Plack::App::File;
use Plack::App::OpenVPN::Status;

sub authenticator {
    my ($username, $password) = @_;
    # pass anyone
    $username && $password ? 1 : 0;
}

builder {
    enable 'Auth::Basic',
        authenticator => \&authenticator, realm => 'OpenVPN Status Area';
    enable "Deflater",
        content_type    => [ 'text/css', 'text/html', 'text/javascript', 'application/javascript' ],
        vary_user_agent => 1;

    mount '/static' => Plack::App::File->new(root => "$FindBin::Bin/static");
    mount '/' => Plack::App::OpenVPN::Status->new(status_from => "$FindBin::Bin/status.log");
};
