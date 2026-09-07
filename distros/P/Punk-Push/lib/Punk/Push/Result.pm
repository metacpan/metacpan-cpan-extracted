package Punk::Push::Result;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

sub new {
    my ($class, %args) = @_;
    return bless {
        endpoint => $args{endpoint},
        status   => $args{status},
        error    => $args{error},
        pruned   => $args{pruned} ? 1 : 0,
        queued   => $args{queued},
    }, $class;
}

sub endpoint { $_[0]{endpoint} }
sub status   { $_[0]{status} }
sub error    { $_[0]{error} }
sub pruned   { $_[0]{pruned} }
sub queued   { $_[0]{queued} }

sub delivered {
    my $s = $_[0]{status};
    return defined $s && $s >= 200 && $s < 300 ? 1 : 0;
}

sub gone {
    my $s = $_[0]{status};
    return defined $s && ($s == 404 || $s == 410) ? 1 : 0;
}

1;

__END__

=head1 NAME

Punk::Push::Result - what one delivery attempt reported

=head1 SYNOPSIS

    for my $r ($c->push_send($user, \%payload)) {
        next if $r->delivered;
        warn $r->endpoint, ' -> ', $r->status // $r->error;
    }

=head1 METHODS

=head2 endpoint

Which subscription this is about.

=head2 status

The HTTP status the push service returned, or undef when the request never
completed.

=head2 error

The transport error, when there was one.

=head2 delivered

True for any 2xx. RFC 8030 specifies C<201>, but some push services answer
C<200> or C<202>, and treating only C<201> as success reports a working
delivery as a failure.

=head2 gone

True for C<404> and C<410> - the push service saying this subscription is
permanently gone. Everything else, C<5xx> included, is a fact about the
service rather than about the subscription.

=head2 pruned

Whether the stored subscription was deleted as a result.

=head2 queued

The job id, when the send was handed to L<Punk::Queue> rather than performed.
A queued result has no C<status> yet: nothing has been sent.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
