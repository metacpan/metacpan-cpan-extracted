package Punk::Push::Subscription;

use 5.010;
use strict;
use warnings;
use Carp ();
use MIME::Base64 ();

our $VERSION = '0.02';

sub new {
    my ($class, $raw) = @_;
    my $self = $class->check($raw);
    return bless $self, $class;
}

sub endpoint { $_[0]{endpoint} }
sub p256dh   { $_[0]{p256dh} }
sub auth     { $_[0]{auth} }

sub check {
    my ($class, $raw) = @_;

    Carp::croak('Punk::Push: a subscription must be a hashref')
        unless ref $raw eq 'HASH';

    my $endpoint = $raw->{endpoint};
    Carp::croak('Punk::Push: a subscription needs an endpoint')
        unless defined $endpoint && length $endpoint;

    Carp::croak("Punk::Push: a subscription endpoint must be an absolute "
              . "https URL, not '$endpoint'")
        unless $endpoint =~ m{\Ahttps://[^/?#\s]+(?:[/?#]|\z)};

    my $keys = $raw->{keys};
    Carp::croak('Punk::Push: a subscription needs keys')
        unless ref $keys eq 'HASH';

    my $p256dh = _decode($keys->{p256dh}, 'p256dh');
    Carp::croak('Punk::Push: p256dh must decode to 65 bytes, got '
              . length($p256dh))
        unless length($p256dh) == 65;
    Carp::croak('Punk::Push: p256dh must be an uncompressed point, '
              . 'beginning 0x04')
        unless substr($p256dh, 0, 1) eq "\x04";

    my $auth = _decode($keys->{auth}, 'auth');
    Carp::croak('Punk::Push: auth must decode to 16 bytes, got '
              . length($auth))
        unless length($auth) == 16;

    return {
        endpoint => $endpoint,
        p256dh   => $keys->{p256dh},
        auth     => $keys->{auth},
    };
}

sub _decode {
    my ($v, $what) = @_;
    Carp::croak("Punk::Push: a subscription needs a $what key")
        unless defined $v && length $v;
    Carp::croak("Punk::Push: $what must be a base64url string")
        if ref $v || $v =~ m{[^A-Za-z0-9_\-=]};
    return MIME::Base64::decode_base64url($v);
}

1;

__END__

=head1 NAME

Punk::Push::Subscription - what a browser hands you, checked

=head1 SYNOPSIS

    my $sub = Punk::Push::Subscription->new($c->req->json);

=head1 DESCRIPTION

The shape C<PushSubscription.toJSON()> produces:

    {
      "endpoint": "https://fcm.googleapis.com/fcm/send/...",
      "keys": { "p256dh": "<base64url>", "auth": "<base64url>" }
    }

=head2 This is a security boundary, not a formality

These values arrive from a browser and go into a crypto routine and an
outbound HTTP request.

The C<endpoint> must be an absolute C<https> URL. It is a URL this server will
POST to, on a schedule the client chose, with a body the client cannot read -
which is a server-side request forgery primitive if it is not constrained.

C<p256dh> must decode to exactly 65 bytes beginning C<0x04>, an uncompressed
P-256 point, and C<auth> to exactly 16. Both are checked on the B<decoded>
bytes, because a base64url decoder that ignores a bad character turns a
corrupt key into a short one, and the length is what catches that.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
