package Net::NATS::Subscription;

use Class::XSAccessor {
    constructors => [ 'new' ],
    accessors => [
        'subject',
        'group',
        'sid',
        'callback',
        'client',
    ],
    lvalue_accessors => [
        'message_count',
        'max_msgs',
    ],
    defined_predicates => {
        defined_max => 'max_msgs',
    },
};

sub auto_unsubscribe {
    my $self = shift;
    my ($max_msgs) = @_;
    $self->client->unsubscribe($self, $max_msgs);
}

sub unsubscribe {
    my $self = shift;
    $self->client->unsubscribe($self);
}

1;
