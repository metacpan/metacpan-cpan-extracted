use strict;
use warnings FATAL => 'all';

use Mojo::Rx::ConnectableObservable;

*Mojo::Rx::op_multicast = sub {
    my ($subject_factory) = @_;

    return sub {
        my ($source) = @_;

        return Mojo::Rx::ConnectableObservable->new($source, $subject_factory);
    };
};

1;
