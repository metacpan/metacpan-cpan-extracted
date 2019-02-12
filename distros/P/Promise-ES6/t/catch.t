package t::catch;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent qw(PromiseTest);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::More;

use Promise::ES6;

sub reject_catch : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $reject->('oh my god!');
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });
    is $self->await($p), 'oh my god!';
}

sub then_reject_catch : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        return Promise::ES6->new(sub {
            my ($resolve, $reject) = @_;
            die { message => 'oh my god', value => $value };
        });
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });
    is_deeply $self->await($p), { message => 'oh my god', value => 123 };
}

sub asyncreject_catch : Tests {
    my ($self) = @_;

    my $reject;
    local $SIG{'USR1'} = sub { $reject->('oh my god!') };

    my $p = Promise::ES6->new(sub {
        (undef, $reject) = @_;

        local $SIG{'CHLD'} = 'IGNORE';
        fork or do {
            Time::HiRes::sleep(0.1);
            kill 'USR1', getppid();
            exit;
        };
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });
    is $self->await($p), 'oh my god!';
}

sub exception_catch : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!' };
    });
    is_deeply exception {
        $self->await($p);
    }, { message => 'oh my god!!' };
}

sub then_exception_await : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        die { message => $value };
    });
    is_deeply exception { $self->await($p) }, { message => 123 };
}

sub exception_then_await : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!!' }
    })->then(sub {
        my ($value) = @_;
        #
    }, sub {
        my ($reason) = @_;
        return { reason => $reason };
    });
    is_deeply $self->await($p), { reason => { message => 'oh my god!!!' } };
}

sub exception_catch_then_await : Tests {
    my ($self) = @_;

    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!!' }
    })->catch(sub {
        my ($reason) = @_;
        return { recover => 1, reason => $reason };
    })->then(sub {
        my ($value) = @_;
        return $value;
    });
    is_deeply $self->await($p), { recover => 1, reason => { message => 'oh my god!!!' } };
}

__PACKAGE__->runtests;
