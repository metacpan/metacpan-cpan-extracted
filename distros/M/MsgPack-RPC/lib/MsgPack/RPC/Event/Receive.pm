package MsgPack::RPC::Event::Receive;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::RPC::Event::Receive::VERSION = '2.0.3';
use Moose;

extends 'Beam::Event';

has message => (
    is => 'ro',
    required => 1,
    handles => [ qw/ id is_request is_response is_notification params method all_params / ],
);

sub resp {
    my $self = shift;

    $self->emitter->send_response( $self->id, shift );
}

sub error {
    my $self = shift;

    $self->emitter->send_response_error( $self->id, shift );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::RPC::Event::Receive

=head1 VERSION

version 2.0.3

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
