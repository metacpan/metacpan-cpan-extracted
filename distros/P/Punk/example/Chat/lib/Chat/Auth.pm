package Chat::Auth;

use strict;
use warnings;

# The checker behind the spec's `adminToken` security scheme, wired up in
# Chat.pm. Punk compiles the spec's security requirements into one guard per
# operation at boot; this is called with the credential already pulled out of
# the request the way the scheme declares it (here, the Bearer token).
#
# A true return authorizes and lands in $c->stash->{auth}{adminToken}; a
# false one moves on to the next alternative, and 401 is the answer when none
# pass - before any body is read. An operation that requires a scheme with no
# checker registered croaks at boot rather than serving an open door.
#
# It lives here rather than under Chat::Controller::API because it is not an
# operation: everything in the controller namespace is loaded and scanned for
# methods named after operationIds, and a checker has no business in that
# search.

sub admin_token {
    my ($token, $c, $operation_id, $scopes) = @_;

    my $want = defined $ENV{PUNK_CHAT_ADMIN_TOKEN}
             ? $ENV{PUNK_CHAT_ADMIN_TOKEN} : 'punk-admin';

    return undef unless defined $token && _constant_eq($token, $want);
    return { name => 'admin', via => 'bearer' };
}

# Constant time over the length compared, so the check does not leak the
# token one byte at a time. A real deployment would compare hashes.
sub _constant_eq {
    my ($got, $want) = @_;
    return 0 unless length $got == length $want;
    my $diff = 0;
    $diff |= ord(substr $got, $_, 1) ^ ord(substr $want, $_, 1)
        for 0 .. length($want) - 1;
    return $diff == 0;
}

1;
