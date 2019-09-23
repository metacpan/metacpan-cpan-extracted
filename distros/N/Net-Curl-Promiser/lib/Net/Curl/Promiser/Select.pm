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

=cut

#----------------------------------------------------------------------

use parent 'Net::Curl::Promiser';

use Net::Curl::Multi ();

#----------------------------------------------------------------------

=head1 C<process( $READ_MASK, $WRITE_MASK )>

Instances of this class should pass the read and write bitmasks
to the C<process()> method that otherwise would be passed to Perl’s
C<select()> built-in.

=head1 METHODS

The following are added in addition to the base class methods:

=head2 ($rmask, $wmask, $emask) = I<OBJ>->get_vecs();

Returns the bitmasks to use as input to C<select()>.

Note that, since these are copies of I<OBJ>’s internal values, you don’t
need to copy them again before calling C<select()>.

=cut

sub get_vecs {
    my ($self) = @_;

    return @{$self}{'rin', 'win', 'ein'};
}

#----------------------------------------------------------------------

=head2 @fds = I<OBJ>->get_fds();

Returns the file descriptors that I<OBJ> tracks—or, in scalar context, the
count of such. Useful to check for exception events.

=cut

sub get_fds {
    return keys %{ $_[0]{'rfds'} };
}

#----------------------------------------------------------------------

=head2 @fds = I<OBJ>->get_timeout();

Calls the base class’s implementation of this method and then
translates it to seconds (since that’s what C<select()> expects).

=cut

sub get_timeout {
    return $_[0]->SUPER::get_timeout() / 1000;
}

#----------------------------------------------------------------------

sub _INIT {
    my ($self) = @_;

    $_ = q<> for @{$self}{ qw( rin win ein ) };

    $_ = {} for @{$self}{ qw( rfds wfds ) };

    return;
}

sub _GET_FD_ACTION {
    my ($self, $args_ar) = @_;

    my %fd_action;

    $fd_action{$_} = Net::Curl::Multi::CURL_CSELECT_IN() for keys %{ $self->{'rfds'} };
    $fd_action{$_} += Net::Curl::Multi::CURL_CSELECT_OUT() for keys %{ $self->{'wfds'} };

    return \%fd_action;
}

sub _SET_POLL_IN {
    my ($self, $fd) = @_;
    $self->{'rfds'}{$fd} = $self->{'fds'}{$fd} = delete $self->{'wfds'}{$fd};

    vec( $self->{'rin'}, $fd, 1 ) = 1;
    vec( $self->{'win'}, $fd, 1 ) = 0;
    vec( $self->{'ein'}, $fd, 1 ) = 1;

    return;
}

sub _SET_POLL_OUT {
    my ($self, $fd) = @_;
    $self->{'wfds'}{$fd} = $self->{'fds'}{$fd} = delete $self->{'rfds'}{$fd};

    vec( $self->{'rin'}, $fd, 1 ) = 0;
    vec( $self->{'win'}, $fd, 1 ) = 1;
    vec( $self->{'ein'}, $fd, 1 ) = 1;

    return;
}

sub _SET_POLL_INOUT {
    my ($self, $fd) = @_;
    $self->{'rfds'}{$fd} = $self->{'wfds'}{$fd} = $self->{'fds'}{$fd} = undef;

    vec( $self->{'rin'}, $fd, 1 ) = 1;
    vec( $self->{'win'}, $fd, 1 ) = 1;
    vec( $self->{'ein'}, $fd, 1 ) = 1;

    return;
}

sub _STOP_POLL {
    my ($self, $fd) = @_;
    delete $self->{'rfds'}{$fd};
    delete $self->{'wfds'}{$fd};
    delete $self->{'fds'}{$fd};

    vec( $self->{'rin'}, $fd, 1 ) = 0;
    vec( $self->{'win'}, $fd, 1 ) = 0;
    vec( $self->{'ein'}, $fd, 1 ) = 0;

    return;
}

1;
