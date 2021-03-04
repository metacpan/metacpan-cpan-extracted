package RxPerl::Observable;
use strict;
use warnings;

use RxPerl::Subscription;
use RxPerl::Subscriber;

use Scalar::Util 'reftype';
use Carp 'croak';

# an observable is something you can subscribe to.

# The class RxPerl::Observable has a method 'new'
#   (arguments) This method accepts a function as an argument.
#                   This function:
#                       - accepts a subscriber as its only argument
#                       - calls $subscriber->next,error,complete at its appropriate moments
#                       - returns a subref, which contains the cleanup required, when the subscriber wishes to unsubscribe
#   (return)    This method returns an instance of the RxPerl::Observable
#                   This RxPerl::Observable instance contains:
#                       - the function

# Objects of the RxPerl::Observable class have a 'subscribe' method
#   (arguments) This method accepts zero to three arguments, which should be converted by the subscribe method to a clean hashref ('the subscriber') with the corresponding 0-3 keys
#   (body)      This method calls the $function that RxPerl::Observable->new received as argument (and that initiates the subscription)
#   (return)    This method returns a new RxPerl::Subscription object, that contains the "cleanup subref" returned by $function

our $VERSION = "v6.6.1";

sub new {
    my ($class, $function) = @_;

    my $self = {function => $function};

    bless $self, $class;
}

sub subscribe {
    my ($self, @args) = @_;

    my $subscriber = {};
    bless $subscriber, 'RxPerl::Subscriber';

    if ((reftype($args[0]) // '') eq 'HASH') {
        $args[0]{_subscription} = delete $args[0]{new_subscription} if $args[0]{new_subscription};
        @$subscriber{qw/ next error complete _subscription /} = @{ $args[0] }{qw/ next error complete _subscription /};
    } else {
        @$subscriber{qw/ next error complete /} = @args;
    }

    $subscriber->{error} //= sub {
        my ($err) = @_;

        # TODO: shouldn't croak immediately, to be like rxjs, but on the next tick
        croak $err;
    };

    my $subscription = $subscriber->{_subscription} //= RxPerl::Subscription->new;
    $subscriber->{closed_ref} = \$subscription->{closed};

    # don't continue if the subscription has already closed (complete/error)
    return $subscription if $subscription->{closed};

    $subscription->_add_to_subscribers($subscriber);

    my $fn = $self->{function};

    my @cbs = $fn->($subscriber);

    $subscription->add_dependents(@cbs);

    return $subscription;
}

sub pipe {
    my ($self, @operators) = @_;

    my $result = $self;
    $result = $_->($result) foreach @operators;

    return $result;
}

1;
