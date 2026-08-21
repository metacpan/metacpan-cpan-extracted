package Punk::Plugin::RequestId;

use 5.010;
use strict;
use warnings;
use parent 'Punk::Plugin';
use Carp ();
use Punk ();

our $VERSION = '0.27';

# The id path itself is C - include/punk/punk_reqid.h and xs/reqid.xs.

sub register {
    my ($self, $app, $opts) = @_;
    $opts ||= {};

    my $header = exists $opts->{header} ? $opts->{header} : 'X-Request-Id';
    $header = undef unless $header;
    if (defined $header) {
        Carp::croak("Punk::Plugin::RequestId: header '$header' is not a "
                  . 'usable header name')
            if $header =~ /[^A-Za-z0-9_-]/;
    }

    my $envkey;
    if ($opts->{trust_header}) {
        my $from = defined $header ? $header
                 : do {
                     Carp::croak('Punk::Plugin::RequestId: trust_header needs '
                               . 'a header to read; it cannot be used with '
                               . 'header => 0');
                   };
        ($envkey = uc $from) =~ tr/-/_/;
        $envkey = "HTTP_$envkey";
    }

    __PACKAGE__->_enable($app, $header, $envkey);

    $app->helper(request_id => \&_id);

    return;
}

1;

__END__

=head1 NAME

Punk::Plugin::RequestId - give every request an id

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    plugin 'RequestId';

    get '/' => sub {
        my ($c) = @_;
        $c->log->info('serving the front page');   # carries the id
        $c->text($c->request_id);
    };

Turn the response header off, or rename it:

    plugin 'RequestId' => { header => 0 };
    plugin 'RequestId' => { header => 'X-Correlation-Id' };

=head1 DESCRIPTION

Every request gets an id. It is readable as C<< $c->request_id >>, returned to
the client as C<X-Request-Id>, and - once you are past this plugin's own
phase - attached to every log line the request produces.

The point is the join: a user quotes the id their browser showed them, and
that one string finds every line the request wrote.

=head2 Every response, not just the ones that matched a route

The id is minted before routing, so a request that 404s, one that 405s, one
answered by a static file and one answered by a mounted PSGI app all have
one. That is deliberate: a response with no id is one nobody can trace, and
the untraceable ones are disproportionately the ones somebody is trying to
trace.

=head2 In the log

Every line a request writes carries the id, with nothing passed at the call
site:

    $c->log->info('listing books');
    # [2026-08-20T15:38:29Z] [info] GET / - listing books request_id=01a01f...

It is a B<field>, not a new position in the line. The shape up to the message
is unchanged - C<[time] [level] METHOD /path - message> - so anything already
splitting on that prefix keeps working, and the id joins the fields a record
was always allowed to add after it. Under C<< format => 'json' >> it is a
C<request_id> key.

The id reaches the logger through C<psgix.request_id>, the PSGI extension key,
so a middleware or a mounted app in the same stack sees the same value.

A line logged outside a request - at worker startup, say - carries B<no> id
rather than the last one this worker served.

=head2 The id

A UUIDv7 (RFC 9562) as 32 lowercase hex characters: 48 bits of millisecond
timestamp followed by randomness.

    01a01fa76d557485932fd12163f36cb6

=head1 OPTIONS

=over 4

=item C<trust_header>

Adopt an id handed in by a proxy instead of minting a fresh one. B<Off by
default, and deliberately so.>

    plugin 'RequestId' => { trust_header => 1 };

Punk sits behind a proxy in production and on C<localhost> in development, and
in the second case the header is whatever the client felt like sending. A
default that trusted it would be a default that writes attacker-chosen bytes
into the log of every application that copied the synopsis.

Turn it on only where something in front of you sets the header and strips
whatever the client sent.

An adopted value must be 1 to 128 bytes of printable ASCII with no space
(C<0x21> to C<0x7e>). That covers a UUID, hex, base64, base64url and a W3C
traceparent, and excludes CR, LF, NUL, tab, every other control byte and
everything above ASCII - because the value reaches a log line and a response
header, where a CR forges an entry in the first and splits the second.

A value that fails is B<replaced> by a fresh id, never trimmed into shape: a
mangled id correlates with nothing at either end, and silently editing what a
client sent produces a third value matching neither. Refusals are counted -
see L</stats>.

Using it with C<< header => 0 >> croaks at boot, since there would be no
header to read.

=item C<header>

The response header carrying the id, C<X-Request-Id> by default. Pass a
different name to rename it, or a false value to send no header at all - the
id is still minted, still on C<< $c->request_id >>, and still in the logs.

A name containing anything outside C<[A-Za-z0-9_-]> croaks at boot rather
than writing a malformed header.

=back

=head1 METHODS

=head2 request_id

    my $id = $c->request_id;

The current request's id. A real method on the context, installed once at
C<to_app>.

=head2 stats

    my %s = Punk::Plugin::RequestId->stats;
    # ( minted => 1200, adopted => 340, rejected => 2 )

Process-wide counts. C<adopted> and C<rejected> stay at zero unless
C<trust_header> is on, and a rising C<rejected> is somebody sending ids that
are not ids - which is worth being able to see rather than discarding
silently.

=head1 CAVEATS

By default an inbound C<X-Request-Id> is B<ignored> and every request gets a
fresh id. See C<trust_header> above for what it takes to change that, and why
it is not the default.

=head1 SEE ALSO

L<Punk>, L<Punk::Plugin>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
