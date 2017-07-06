package RabbitMQ::Consumer::Batcher::Message;
use Moose;

use namespace::autoclean;
use Moose::Util::TypeConstraints qw(duck_type);

=head1 NAME

RabbitMQ::Consumer::Batcher::Message - rmq message

=head1 SYNOPSIS

    RabbitMQ::Consumer::Batcher::Message->new(
        header   => $msg->{header},
        body     => $msg->{body},
        deliver  => $msg->{deliver},
        consumer => $consumer,
    );

=head1 DESCRIPTION

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 header

=cut

has 'header' => (
    is       => 'ro',
    #bless(
    #    {
    #        'content_type'  => 'application/json',
    #        'priority'      => 1,
    #        'timestamp'     => 1498807603,
    #        'user_id'       => 'guest',
    #        'delivery_mode' => 1,
    #        'headers'       => {
    #            'trials' => '8'
    #        }
    #    },
    #    'Net::AMQP::Protocol::Basic::ContentHeader'
    #);
    isa      => duck_type('interface like Net::AMQP::Protocol::Basic::ContentHeader', [qw(content_type priority timestamp user_id delivery_mode headers)]),
    required => 1,
);

=head4 body

=cut

has 'body' => (
    is       => 'ro',
    isa      => duck_type('interface like Net::AMQP::Frame::Body', [qw(payload)]),
    required => 1,
);

=head4 deliver

=cut

has 'deliver' => (
    is       => 'ro',
    isa      => duck_type('interface like Net::AMQP::Frame::Method', [qw(method_frame)]),
    required => 1,
);

=head4 consumer

=cut

has 'consumer' => (
    is       => 'ro',
    isa      => duck_type('Consumer interface', [qw(ack reject reject_and_republish)]),
    required => 1,
);

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

__PACKAGE__->meta->make_immutable();
1;
