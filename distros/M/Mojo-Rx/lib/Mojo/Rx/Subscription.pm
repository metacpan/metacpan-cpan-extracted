package Mojo::Rx::Subscription;
use strict;
use warnings FATAL => 'all';

use Scalar::Util 'blessed', 'reftype', 'weaken';

our $VERSION = "v0.12.0";

sub new {
    my ($class) = @_;

    my $self = {
        # the 'subrefs' key will be created by autovivification
        closed => 0,
        subscribers => [],
    };

    bless $self, $class;
}

sub _execute_item {
    my ($self, $item) = @_;

    if (! defined $item) {
        return undef;
    } elsif (ref $item ne '') {
        if (reftype $item eq 'CODE') {
            $item->();
        }
        elsif (defined blessed($item) and $item->isa('Mojo::Rx::Subscription')) {
            $item->unsubscribe unless $item eq $self;
        }
        elsif (reftype $item eq 'ARRAY') {
            $self->_execute_item($_) foreach @$item;
        }
        elsif (reftype $item eq 'REF') {
            # ref to ::Subscription object
            $self->_execute_item($$item);
        }
        elsif (reftype $item eq 'SCALAR') {
            # ref to undef, or some other invalid construct
            return undef;
        }
        elsif (reftype $item eq 'HASH' and not defined blessed($item)) {
            $self->_execute_item([values %$item]);
        }
    }
}

sub add_to_subscribers {
    my ($self, $subscriber) = @_;

    push @{ $self->{subscribers} }, $subscriber;

    weaken($self->{subscribers}[-1]);

    # wrap 'complete' and 'error' of first subscriber
    if ((grep defined, @{ $self->{subscribers} }) == 1) {
        foreach (qw/ error complete /) {
            # wrap with 'unsubscribe'
            my $orig_fn = $subscriber->{$_};
            $subscriber->{$_} = sub {
                $self->unsubscribe;
                $orig_fn->(@_) if defined $orig_fn;
            }
        }
    }
}

sub add_dependents {
    my ($self, @subrefs) = @_;

    # filter out any non-refs
    @subrefs = grep ref ne '', @subrefs;

    if (! $self->{closed}) {
        $self->{subrefs}{$_} = $_ foreach @subrefs;
    } else {
        $self->_execute_item(\@subrefs);
    }
}

sub unsubscribe {
    my ($self) = @_;

    return if $self->{closed}++;

    # no need for 'of' (or any other observable) to check 'closed status' anymore
    foreach my $subscriber (@{ $self->{subscribers} }) {
        delete @$subscriber{qw/ next error complete /} if defined $subscriber;
    }

    $self->{subscribers} = [];

    $self->_execute_item(delete $self->{subrefs});
}

1;
