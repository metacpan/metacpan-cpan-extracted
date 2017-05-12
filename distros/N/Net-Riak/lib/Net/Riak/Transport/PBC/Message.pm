package Net::Riak::Transport::PBC::Message;
{
  $Net::Riak::Transport::PBC::Message::VERSION = '0.1702';
}

use Moose;
use MooseX::Types::Moose qw/Str HashRef Int/;
use Net::Riak::Types 'Socket';
use Net::Riak::Transport::PBC::Code qw/
  REQ_CODE EXPECTED_RESP RESP_CLASS RESP_DECODER/;
use Net::Riak::Transport::PBC::Transport;

has socket => (
    is        => 'rw',
    isa       => Socket,
    predicate => 'has_socket',
);

has request => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has request_code => (
    required => 1,
    isa => Int,
    is => 'ro',
    lazy_build => 1,
);

has message_type => (
    required => 1,
    isa => Str,
    is => 'ro',
    trigger => sub {
        $_[0]->{message_type} = 'Rpb'.$_[1];
    }
);

has params => (
    is  => 'ro',
    isa => HashRef,
);

sub _build_request_code {
    my $self = shift;
    return REQ_CODE($self->message_type);
}

sub _build_request {
    my $self = shift;
    $self->_pack_request( $self->request_code, $self->encode );
}

sub _pack_request {
    my ($self, $code, $req) = @_;
    my $h = pack('c', $code) . $req;
    use bytes;
    my $len = length $h;
    return pack('N',$len).$h;
}

sub encode {
    my $self = shift;
    return $self->message_type->can('encode')
      ? $self->message_type->encode( $self->params )
      : '';
}

sub decode {
    my ($self, $type, $raw_content) = @_;
    return 'Rpb'.$type->decode($raw_content);
}

sub send {
    my ($self, $cb) = @_;

    die "No socket? did you forget to ->connect?" unless $self->has_socket;

    $self->socket->print($self->request);

    my $resp = $self->handle_response;

    return $resp unless $cb;

    $cb->($resp);
    while (!$resp->done) {
        $resp = $self->handle_response;
#        use YAML::Syck; warn Dump $resp;
        $cb->($resp);
    }
    return 1;
}

sub handle_response {
    my $self = shift;
    my ($code, $resp) = $self->_unpack_response;

    my $expected_code = EXPECTED_RESP($self->request_code);

    if ($expected_code != $code) {
        # TODO throw object
        die "Expecting response type "
            . RESP_CLASS($expected_code)
                . " got " . RESP_CLASS($code);
    }

    return 1 unless RESP_DECODER($code);
    return RESP_DECODER($code)->decode($resp);
}

sub _unpack_response {
    my $self = shift;
    my ( $len, $code, $msg );
    _check($self->socket->read( $len, 4 ));
    $len = unpack( 'N', $len );
    _check($self->socket->read( $code, 1 ));
    $code = unpack( 'c', $code );
    _check($self->socket->read( $msg, $len - 1 ));
    return ( $code, $msg );
}

sub _check {
    defined $_[0]
      or die "failure in reading from the socket. Error were : $!";
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Transport::PBC::Message

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
