# ABSTRACT: Perl wrapper around Wslay websocket library
package Net::WebSocket::EVx;
use strict; use warnings;
use EV ();
use XSLoader ();
our $VERSION;
BEGIN {
    $VERSION = '0.18';
    XSLoader::load(__PACKAGE__, $VERSION);
}
use constant { WS_FRAGMENTED_EOF => 0, WS_FRAGMENTED_ERROR => -1, WS_FRAGMENTED_DATA => 1 };
use Exporter 'import';
our @EXPORT = qw/WS_FRAGMENTED_EOF WS_FRAGMENTED_ERROR WS_FRAGMENTED_NODATA/;

sub new {
    my (undef, $self) = @_;
    $self->{buffering} = 1 unless defined $self->{buffering};
    $self->{type} = 'server' unless defined $self->{type};
    _wslay_event_context_init(
        $self,
        (defined($self->{fd}) && $self->{fd} || fileno($self->{fh})),
        int($self->{type} eq 'server')
    );
    _wslay_event_config_set_no_buffering($self, int(!$self->{buffering}));
    _wslay_event_config_set_max_recv_msg_length($self, $self->{max_recv_size}) if defined $self->{max_recv_size};
    bless $self
}

sub wait { if ($_[1]) { $_[0]->_set_waiter($_[1]) } }

1;
