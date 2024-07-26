package RxPerl::Functions;

use strict;
use warnings;

require RxPerl::Operators::Pipeable;

use Carp 'croak';
use Scalar::Util 'blessed';

use Exporter 'import';
our @EXPORT_OK = qw/
    last_value_from first_value_from is_observable
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "v6.29.2";

sub _promise_class {
    my $fn = (caller(1))[3];
    my $rx_class = $fn;
    $rx_class =~ s/\:\:[^\:]+\z//;
    no strict 'refs';
    my $promise_class = ${ "${rx_class}::promise_class" };
    return wantarray ? ($promise_class, $rx_class) : $promise_class;
}

sub last_value_from {
    my ($observable) = @_;

    my ($promise_class, $rx_class) = _promise_class;
    $promise_class or croak "Promise class not set, set it with: ${rx_class}->set_promise_class(\$promise_class)";

    my ($promise, $resolve, $reject) = do {
        if ($promise_class eq 'Future') {
            my $future = Future->new;
            ( $future, sub { $future->done(@_) }, sub { $future->fail(@_) } );
        } else {
            my ($res, $rej);
            my $p = $promise_class->new(sub {
                ($res, $rej) = @_;
            });
            ( $p, $res, $rej );
        }
    };

    my ($got_value, $last_value);
    $observable->subscribe({
        next     => sub {
            $last_value = $_[0];
            $got_value = 1;
        },
        error    => sub {
            $reject->($_[0]);
        },
        complete => sub {
            if ($got_value) {
                $resolve->($last_value);
            } else {
                $reject->('no elements in sequence');
            }
        },
    });

    return $promise;
}

sub first_value_from {
    my ($observable) = @_;
    return last_value_from(
        $observable->pipe(RxPerl::Operators::Pipeable::op_first())
    );
}

sub is_observable {
    my ($thing) = @_;

    return !!(blessed($thing) && $thing->isa('RxPerl::Observable'));
}

1;
