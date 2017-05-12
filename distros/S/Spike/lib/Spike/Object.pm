package Spike::Object;

use strict;
use warnings;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    return bless { @_ }, $class;
}

sub mk_accessors {
    my $proto = shift;
    my $class = ref $proto || $proto;

    for my $name (@_) {
        no strict 'refs';

        *{"${class}::$name"} = sub {
            my $self = shift;

            return $self->{$name} = shift if @_;
            return $self->{$name};
        }
    }
}

sub mk_ro_accessors {
    my $proto = shift;
    my $class = ref $proto || $proto;

    for my $name (@_) {
        no strict 'refs';

        *{"${class}::$name"} = sub {
            my $self = shift;
            return $self->{$name};
        }
    }
}

1;
