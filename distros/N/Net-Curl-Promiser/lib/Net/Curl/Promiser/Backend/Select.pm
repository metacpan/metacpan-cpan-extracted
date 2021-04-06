package Net::Curl::Promiser::Backend::Select;

use strict;
use warnings;

use parent 'Net::Curl::Promiser::Backend';

sub new {
    my $self = shift()->SUPER::new();

    $_ = q<> for @{$self}{ qw( rin win ein ) };

    $_ = {} for @{$self}{ qw( rfds wfds ) };

    return $self;
}

#----------------------------------------------------------------------

sub get_vecs {
    my ($self) = @_;

    return @{$self}{'rin', 'win', 'ein'};
}

sub get_fds {
    my @fds = (keys %{ $_[0]{'rfds'} }, keys %{ $_[0]{'wfds'} });
    return @fds;
}

#----------------------------------------------------------------------

sub _GET_FD_ACTION {
    my ($self, $args_ar) = @_;

    my %fd_action;

    $fd_action{$_} = Net::Curl::Multi::CURL_CSELECT_IN() for keys %{ $self->{'rfds'} };
    $fd_action{$_} += Net::Curl::Multi::CURL_CSELECT_OUT() for keys %{ $self->{'wfds'} };

    return \%fd_action;
}

sub SET_POLL_IN {
    my ($self, $fd) = @_;
    $self->{'rfds'}{$fd} = $self->{'fds'}{$fd} = delete $self->{'wfds'}{$fd};

    vec( $self->{'rin'}, $fd, 1 ) = 1;
    vec( $self->{'win'}, $fd, 1 ) = 0;
    vec( $self->{'ein'}, $fd, 1 ) = 1;

    return;
}

sub SET_POLL_OUT {
    my ($self, $fd) = @_;
    $self->{'wfds'}{$fd} = $self->{'fds'}{$fd} = delete $self->{'rfds'}{$fd};

    vec( $self->{'rin'}, $fd, 1 ) = 0;
    vec( $self->{'win'}, $fd, 1 ) = 1;
    vec( $self->{'ein'}, $fd, 1 ) = 1;

    return;
}

sub SET_POLL_INOUT {
    my ($self, $fd) = @_;
    $self->{'rfds'}{$fd} = $self->{'wfds'}{$fd} = $self->{'fds'}{$fd} = undef;

    vec( $self->{'rin'}, $fd, 1 ) = 1;
    vec( $self->{'win'}, $fd, 1 ) = 1;
    vec( $self->{'ein'}, $fd, 1 ) = 1;

    return;
}

sub STOP_POLL {
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
