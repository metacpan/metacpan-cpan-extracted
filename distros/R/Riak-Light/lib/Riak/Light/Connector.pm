#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Connector;
{
    $Riak::Light::Connector::VERSION = '0.052';
}
## use critic

use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;
require bytes;

# ABSTRACT: Riak Connector, abstraction to deal with binary messages

has socket => ( is => 'ro', required => 1 );

sub perform_request {
    my ( $self, $message ) = @_;
    my $bytes = pack( 'N a*', bytes::length($message), $message );

    print "Size of the Request " . bytes::length($message) . "\n";

    $self->_send_all($bytes);    # send request
}

sub read_response {
    my $self   = shift;
    my $lenght = $self->_read_lenght();    # read first four bytes

    return unless ($lenght);

    print "Size of the Response $lenght\n";

    $self->_read_all($lenght);             # read the message
}

sub _read_lenght {
    my $self = shift;

    my $first_four_bytes = $self->_read_all(4);

    return unpack( 'N', $first_four_bytes ) if defined $first_four_bytes;

    undef;
}

sub _send_all {
    my ( $self, $bytes ) = @_;

    my $length = bytes::length($bytes);
    my $offset = 0;
    my $sended = 0;
    do {
        $sended = $self->socket->syswrite( $bytes, $length, $offset );

        # error in $!
        return unless defined $sended;

        # test if $sended == 0 and $! EAGAIN, EWOULDBLOCK, ETC...
        return unless $sended;

        $offset += $sended;
    } while ( $offset < $length );

    $offset;
}

sub _read_all {
    my ( $self, $bufsiz ) = @_;

    my $buffer;
    my $offset = 0;
    my $readed = 0;
    do {
        $readed = $self->socket->sysread( $buffer, $bufsiz, $offset );

        # error in $!
        return unless defined $readed;

        # test if $sended == 0 and $! EAGAIN, EWOULDBLOCK, ETC...
        return unless $readed;

        $offset += $readed;
    } while ( $offset < $bufsiz );

    $buffer;
}

1;


=pod

=head1 NAME

Riak::Light::Connector - Riak Connector, abstraction to deal with binary messages

=head1 VERSION

version 0.052

=head1 DESCRIPTION

  Internal class

=head1 AUTHOR

Tiago Peczenyj <tiago.peczenyj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
