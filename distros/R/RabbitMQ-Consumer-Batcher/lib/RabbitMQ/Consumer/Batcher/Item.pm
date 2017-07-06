package RabbitMQ::Consumer::Batcher::Item;
use Moose;

use namespace::autoclean;

=head1 NAME

RabbitMQ::Consumer::Batcher::Item - batch item

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 msg

instance of L<RabbitMQ::Consumer::Batcher::Message>

=cut

has 'msg' => (
    is       => 'ro',
    isa      => 'RabbitMQ::Consumer::Batcher::Message',
    required => 1,
);

=head4 value

=cut

has 'value' => (
    is       => 'ro',
    isa      => 'Defined',
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
