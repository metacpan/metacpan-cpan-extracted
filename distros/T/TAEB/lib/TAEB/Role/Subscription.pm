package TAEB::Role::Subscription;
use Moose::Role;
use List::MoreUtils qw/any/;

requires 'initialize';
before initialize => sub {
    my $self = shift;
    TAEB->publisher->subscribe($self)
        if (any { /^(?:msg|exception|respond)_/ || $_ eq 'send_message' }
            $self->meta->get_method_list);
};

no Moose::Role;

1;

