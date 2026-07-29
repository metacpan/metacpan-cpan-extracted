package Net::WebSocket::EVx;
use strict; use warnings;
use EV ();
use Carp ();
use XSLoader ();
our $VERSION;
BEGIN {
    $VERSION = '0.21';
    XSLoader::load(__PACKAGE__, $VERSION);
}
use constant { WS_FRAGMENTED_EOF => 0, WS_FRAGMENTED_ERROR => -1, WS_FRAGMENTED_DATA => 1,
               WS_RSV_NONE => 0, WS_RSV1_BIT => 0x04 };
use Exporter 'import';
our @EXPORT = qw/WS_FRAGMENTED_EOF WS_FRAGMENTED_ERROR WS_FRAGMENTED_DATA WS_RSV_NONE WS_RSV1_BIT/;

sub new {
    my (undef, $self) = @_;
    $self->{buffering} = 1 unless defined $self->{buffering};
    $self->{type} = 'server' unless defined $self->{type};
    my $fd = defined $self->{fd} ? $self->{fd}
           : defined $self->{fh} ? fileno($self->{fh})
           : Carp::croak(q{Net::WebSocket::EVx: new() needs an open "fh" or a numeric "fd"});
    Carp::croak(q{Net::WebSocket::EVx: "fh" is not an open filehandle}) unless defined $fd;
    Carp::croak("Net::WebSocket::EVx: invalid file descriptor: $fd") unless $fd >= 0;
    bless $self; # before init, so a failure below still gets a DESTROY
    _wslay_event_context_init($self, $fd, int($self->{type} eq 'server'));
    _wslay_event_config_set_no_buffering($self, int(!$self->{buffering}));
    _wslay_event_config_set_max_recv_msg_length($self, $self->{max_recv_size}) if defined $self->{max_recv_size};
    _wslay_event_config_set_allowed_rsv_bits($self, $self->{allowed_rsv}) if defined $self->{allowed_rsv};
    _set_default_rsv($self, $self->{rsv}) if defined $self->{rsv};
    $self
}

sub wait { if ($_[1]) { $_[0]->_set_waiter($_[1]) } }

1;
