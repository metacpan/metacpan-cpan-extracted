#!/usr/bin/env perl

use strict;
use warnings;
use Test2::Bundle::More;
use Test2::Tools::Compare;

# ABSTRACT: testing SYNOPSIS example

BEGIN {
    package My::Message;
    use Moo;
    with 'Moo::Role::ToJSON';

    has feel_like_sharing => (is => 'rw', default => 0);
    has message => (is => 'ro', default => 'Hi Mum!');
    has secret  => (is => 'ro', default => 'I do not like eating healthily');

    sub _build_serializable_attributes { [qw/message secret/] }

    # optional instance method to selectively serialize an attribute
    sub is_attribute_serializable {
        my ($self, $attr) = @_;

        if ($attr eq 'secret' && !$self->feel_like_sharing) {
            # returning a false value won't include attribute when serializing
            return 0;
        }

        return 1;
    }
}

subtest synopsis => \&test_synopsis;

done_testing;

sub test_synopsis {
    my $message = My::Message->new();
    is $message->TO_JSON => {message => 'Hi Mum!'};

    $message->feel_like_sharing(1);
    is $message->TO_JSON =>
        {message => 'Hi Mum!', secret => 'I do not like eating healthily'};
}
