use strict;
use warnings;

use Plack::Builder;

builder {
    enable "Plack::Middleware::GitStatus", (
        path  => '/git-status'
    );

    sub {
        my ($env) = @_;
        return [200, ['Content-Type' => 'text/plain'], ["GitGitGit!!!\n"]];
    };
};
