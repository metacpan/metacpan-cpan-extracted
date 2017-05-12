package Tapir::Server::Handler;

use strict;
use warnings;
use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors(inherited => qw(service methods));

sub add_method {
    my ($class, $method, $modifier) = @_;
    $modifier ||= 'normal';
    if (my $methods = $class->methods) {
        $methods->{$method} = $modifier;
    }
    else {
        $class->methods({ $method => $modifier });
    }
}

sub add_call_actions {
    my ($class, $call) = @_;

    my $call_method_name = $call->method->name;

    my $add_method_action = sub {
        my ($method_name) = @_;
        $call->add_action(sub {
            $class->$method_name($call);
        });
    };

    # Add any 'before' methods
    while (my ($method_name, $modifier) = each %{ $class->methods }) {
        next unless $modifier eq 'before';
        $add_method_action->($method_name);
    }

    # If the method 'foo' exists as a normal (non-modified) method in the class, add that as an action
    if ($class->methods->{$call_method_name} && $class->methods->{$call_method_name} eq 'normal') {
        $add_method_action->($call_method_name);
    }

    # Add any 'after' methods
    while (my ($method_name, $modifier) = each %{ $class->methods }) {
        next unless $modifier eq 'after';
        $add_method_action->($method_name);
    }

    return;
}

1;
