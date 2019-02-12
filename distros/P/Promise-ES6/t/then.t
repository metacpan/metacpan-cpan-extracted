package t::then;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent qw(PromiseTest);

use Time::HiRes;

use Test::More;

use Promise::ES6;

sub then_success : Tests {
    my ($self) = @_;

    my @todo;

    local $SIG{'USR1'} = sub {
        (shift @todo)->();
    };

    my $test_value = 'first';

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @todo, sub {
            is $test_value, 'first';
            $test_value = 'second';
            $resolve->('first resolve');
        };
    })->then(sub {
        my ($value) = @_;
        is $value, 'first resolve';
        is $test_value, 'second';
        $test_value = 'third';
        return 'second resolve';
    })->then(sub {
        my ($value) = @_;
        is $value, 'second resolve';

        is $test_value, 'third';
        $test_value = 'fourth';

        return Promise::ES6->new(sub {
            my ($resolve, $reject) = @_;

            push @todo, sub {
                is $test_value, 'fourth';
                $test_value = 'fifth';
                $resolve->('third resolve');
            };
        });
    });

    local $SIG{'CHLD'} = 'IGNORE';
    fork or do {
        for (1, 2) {
            Time::HiRes::sleep(0.2);
            kill 'USR1', getppid();
        }

        exit;
    };

    is( $self->await($p), 'third resolve' );
}

sub then_success_with_no_handler : Tests {
    my ($self) = @_;

    my $test_value = 'first';

    my @todo;

    local $SIG{'USR1'} = sub {
        (shift @todo)->();
    };

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @todo, sub {
            is $test_value, 'first';
            $test_value = 'second';
            $resolve->('first resolve');
        };
    });

    local $SIG{'CHLD'} = 'IGNORE';
    fork or do {
        Time::HiRes::sleep(0.2);
        kill 'USR1', getppid();

        exit;
    };

    is( $self->await($p), 'first resolve' );
}

sub already_resolved : Tests {
    my $called = 0;
    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->('executed');
    })->then(sub {
        my ($value) = @_;
        $called = 'called';
    });
    is $called, 'called', 'call fulfilled callback if promise already reasolved';
}

__PACKAGE__->runtests;
