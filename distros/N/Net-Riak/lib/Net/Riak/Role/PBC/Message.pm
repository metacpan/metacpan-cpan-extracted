package Net::Riak::Role::PBC::Message;
{
  $Net::Riak::Role::PBC::Message::VERSION = '0.1702';
}

use Moose::Role;
use Net::Riak::Transport::PBC::Message;

sub send_message {
    my ( $self, $type, $params, $cb ) = @_;

    $self->connect unless $self->connected;

    my $message = Net::Riak::Transport::PBC::Message->new(
        message_type => $type,
        params       => $params || {},
    );

    $message->socket( $self->socket );

    return $message->send($cb);
}

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::PBC::Message

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
