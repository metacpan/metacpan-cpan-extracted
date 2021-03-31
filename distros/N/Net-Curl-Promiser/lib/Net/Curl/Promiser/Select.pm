package Net::Curl::Promiser::Select;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Curl::Promiser::Select

=head1 DESCRIPTION

This module implements L<Net::Curl::Promiser> via Perl’s
L<select()|perlfunc/select> built-in.

See F</examples> in the distribution for a fleshed-out demonstration.

This is “the hard way” to do this, by the way. Your life will be simpler
if you use (or create) an event-loop-based implementation like
L<Net::Curl::Promiser::AnyEvent> or L<Net::Curl::Promiser::IOAsync>.
See F</examples> for comparisons.

=cut

#----------------------------------------------------------------------

use parent 'Net::Curl::Promiser';

use Net::Curl::Promiser::Backend::Select;

#----------------------------------------------------------------------

=head1 METHODS

The following are added in addition to the base class methods:

=head2 ($rmask, $wmask, $emask) = I<OBJ>->get_vecs();

Returns the bitmasks to use as input to C<select()>.

Note that, since these are copies of I<OBJ>’s internal values, you don’t
need to copy them again before calling C<select()>.

=cut

sub get_vecs {
    return shift()->{'backend'}->get_vecs();
}

#----------------------------------------------------------------------

=head2 @fds = I<OBJ>->get_fds();

Returns the file descriptors that I<OBJ> tracks—or, in scalar context, the
count of such. Useful to check for exception events.

=cut

sub get_fds {
    return shift()->{'backend'}->get_fds();
}

#----------------------------------------------------------------------

=head2 $obj = I<OBJ>->process( $READ_MASK, $WRITE_MASK )

Tell the underlying L<Net::Curl::Multi> object which socket events have
happened. $READ_MASK and $WRITE_MASK are as “left” by Perl’s
C<select()> built-in.

If, in fact, no events have happened, then this calls
C<socket_action(CURL_SOCKET_TIMEOUT)> on the
L<Net::Curl::Multi> object (similar to C<time_out()>).

Finally, this reaps whatever pending HTTP responses may be ready and
resolves or rejects the corresponding Promise objects.

Returns I<OBJ>.

=cut

sub process {
    my ($self, @fd_action_args) = @_;

    $self->{'backend'}->process( $self->{'multi'}, \@fd_action_args );

    return $self;
}

#----------------------------------------------------------------------

=head2 $is_active = I<OBJ>->time_out();

Tell the underlying L<Net::Curl::Multi> object that a timeout happened,
and reap whatever pending HTTP responses may be ready.

Calls C<socket_action(CURL_SOCKET_TIMEOUT)> on the
underlying L<Net::Curl::Multi> object. The return is the same as
that operation returns.

Since C<process()> can also do the work of this function, a call to this
function is just an optimization.

This should only be called from event loop logic.

=cut

sub time_out {
    my ($self) = @_;

    return $self->{'backend'}->time_out( $self->{'multi'} );
}

#----------------------------------------------------------------------

=head2 $num = I<OBJ>->get_timeout()

Like libcurl’s L<curl_multi_timeout(3)>, but sometimes returns different
values depending on the needs of I<OBJ>.

(NB: This value is in I<seconds>, not milliseconds.)

This should only be called (if it’s called at all) from event loop logic.

=cut

sub get_timeout {
    my ($self) = @_;

    my $timeout = $self->{'backend'}->get_timeout( $self->{'multi'} );

    return( ($timeout == -1) ? $timeout : $timeout / 1000 );
}

#----------------------------------------------------------------------

sub _INIT {
    return Net::Curl::Promiser::Backend::Select->new();
}


1;
