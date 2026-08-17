package Punk::RateLimit;

use strict;
use warnings;

our $VERSION = '0.14';

# Documentation only. The `rate_limit` keyword and the enforcement it installs
# live in C - Punk::App::rate_limit (xs/ratelimit.xs) captures a rule into a
# magic-CV closure whose body (punk_ratelimit.h) runs on every request with no
# Perl frame - and the $c bridges block_ip / unblock_ip / rate_hit are in
# xs/context.xs. Requiring this module just documents the feature; it defines
# no subs of its own.

1;

__END__

=head1 NAME

Punk::RateLimit - rate limiting and IP blocking over Hyperman's shared arena

=head1 SYNOPSIS

    use Punk;

    # a loose limit on everything, keyed by client IP
    rate_limit limit => 300, window => 60;

    # a tighter one on the API, keyed by an API-key header
    rate_limit for => '/api', by => 'header:X-Api-Key',
               limit => 60, window => 60, tag => 'api';

    # or a custom identity
    rate_limit by => sub { my ($c) = @_; $c->session->{user} }, limit => 20;

    # block an abuser from a handler; the edge drops it next time
    post '/login' => sub {
        my ($c) = @_;
        if (too_many_failures($c)) { $c->block_ip(undef, 3600); }
        ...
    };

=head1 DESCRIPTION

C<rate_limit> installs a before_dispatch that answers B<429 Too Many Requests>
(with C<Retry-After> and the C<X-RateLimit-*> headers) when a caller exceeds
the limit for the rule. The counters live in Hyperman's shared arena, mapped
before its workers fork, so a limit is exact across the whole pool rather than
per worker. It is C<by> the client IP by default; C<< by => 'header:NAME' >>
keys on a request header, and C<< by => sub { ... } >> on whatever the coderef
returns for a context. C<for> scopes a rule to a path prefix, C<tag> names its
counter namespace. Declare it more than once for layered limits.

Blocking is separate and cheaper: C<< $c->block_ip($ip, $ttl) >> adds an IP to
the same arena's denylist, and Hyperman drops it at C<accept> - before a byte
is read - on its next connection. C<< $c->unblock_ip($ip) >> lifts it. Both
default C<$ip> to the current request's C<REMOTE_ADDR>. C<< $c->rate_hit($key,
$limit, $window) >> is the raw counter check, returning
C<($ok, $remaining, $reset)>.

Everything B<fails open>: with no Hyperman E<gt>= ABI v3 under the application
the limiter allows every request and blocking is a no-op, so it is never the
reason a good request is refused.

=head1 SEE ALSO

L<Punk>, L<Hyperman>.

=cut
