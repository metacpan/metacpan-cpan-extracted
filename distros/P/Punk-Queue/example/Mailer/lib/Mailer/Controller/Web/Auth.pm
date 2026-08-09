package Mailer::Controller::Web::Auth;

use strict;
use warnings;
use parent 'Punk::Controller';

# The admin guard. Punk::Plugin::Queue refuses to mount the admin UI
# without one, and the reason is worth stating plainly: that UI retries and
# removes jobs, stops workers and runs crons. Unguarded, it is an
# unauthenticated control plane over everything the queue does.
#
# It is an ordinary `under` guard, resolved from 'Web::Auth#admin' at boot
# exactly like a route target. A reference return short-circuits the
# request with that response; returning nothing lets it through.
#
# This one is a stand-in - a shared token in a cookie or a header - because
# an example should not ship an opinion about your identity system. Swap it
# for whatever the rest of your app already does: a session check, an LDAP
# group, an OIDC claim.

sub admin {
    my ($c) = @_;

    return if _authorized($c);

    return [401, ['Content-Type' => 'text/plain; charset=utf-8',
                  'WWW-Authenticate' => 'Bearer realm="punk-queue"'],
            ["the queue admin UI needs the admin token\n"
           . "try: /queue?token=" . _token() . "\n"]];
}

sub _authorized {
    my ($c) = @_;

    # Already signed in for this session.
    return 1 if $c->session->{admin};

    my $given = $c->param('token');
    if (!defined $given) {
        my $auth = $c->req->header('Authorization') // '';
        $given = $1 if $auth =~ /\ABearer\s+(\S+)\z/;
    }
    return 0 unless defined $given && $given eq _token();

    $c->session->{admin} = 1;
    return 1;
}

sub _token { return $ENV{MAILER_ADMIN_TOKEN} || 'punk-queue-admin' }

1;
