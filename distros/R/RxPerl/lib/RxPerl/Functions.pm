package RxPerl::Functions;

use strict;
use warnings;

require RxPerl::Operators::Pipeable;

use Exporter 'import';
our @EXPORT_OK = qw/
    last_value_from first_value_from
/;

our $VERSION = "v6.6.1";

sub _promise_class {
    my $fn = (caller(1))[3];
    my $rx_class = $fn;
    $rx_class =~ s/\:\:[^\:]+\z//;
    no strict 'refs';
    my $promise_class = ${ "${rx_class}::promise_class" };
    return $promise_class;
}

sub last_value_from {
    my ($observable) = @_;

    my $promise_class = _promise_class;
    my $p = $promise_class->new(sub {
        my ($resolve, $reject) = @_;

        my ($got_value, $last_value);
        $observable->subscribe({
            next     => sub {
                my ($value) = @_;

                $last_value = $value;
                $got_value = 1;
            },
            error    => sub {
                my ($error) = @_;

                $reject->($error);
            },
            complete => sub {
                if ($got_value) {
                    $resolve->($last_value);
                } else {
                    $reject->('no elements in sequence');
                }
            },
        });
    });
}

sub first_value_from {
    my ($observable) = @_;
    return last_value_from(
        $observable->pipe(RxPerl::op_first())
    );
}

1;