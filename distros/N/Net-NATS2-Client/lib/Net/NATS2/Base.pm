package Net::NATS2::Base;

use v5.10;
use strict;
use warnings;

sub import {
    my ($class, @options) = @_;
    my $target = caller;
    no strict 'refs';

    *{"${target}::has"} = \&has;
    return if grep { $_ eq '-no_new' } @options;

    *{"${target}::new"} = sub {
        my ($class, %args) = @_;
        return bless \%args, $class;
    };
}

sub has {
    my ($attribute, $default) = @_;
    my $target = caller;
    no strict 'refs';

    *{"${target}::${attribute}"} = sub {
        my $self = shift;

        if (@_) {
            $self->{$attribute} = shift;
            return $self;
        }

        if (!exists $self->{$attribute} && defined $default) {
            $self->{$attribute} = ref $default eq 'CODE' ? $default->($self) : $default;
        }

        return $self->{$attribute};
    };
}

1;
