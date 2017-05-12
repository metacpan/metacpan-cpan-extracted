package t::catch;
use strict;
use warnings;

use parent qw(Test::Class);
use Test::Fatal qw(exception);
use Test::More;

use Promise::Tiny::AnyEvent;

sub reject_catch : Tests {
    my $p = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        $reject->('oh my god!');
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });
    is $p->await(), 'oh my god!';
}

sub then_reject_catch : Tests {
    my $p = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        return Promise::Tiny::AnyEvent->new(sub {
            my ($resolve, $reject) = @_;
            die { message => 'oh my god', value => $value };
        });
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });
    is_deeply $p->await(), { message => 'oh my god', value => 123 };
}

sub asyncreject_catch : Tests {
    my $p = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        my $w; $w = AnyEvent->timer(
            after => 0.1,
            cb => sub {
                undef $w;
                $reject->('oh my god!');
            }
        );
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });
    is $p->await(), 'oh my god!';
}

sub exception_catch : Tests {
    my $p = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!' };
    });
    is_deeply exception {
        $p->await();
    }, { message => 'oh my god!!' };
}

sub then_exception_await : Tests {
    my $p = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(123);
    })->then(sub {
        my ($value) = @_;
        die { message => $value };
    });
    is_deeply exception { $p->await() }, { message => 123 };
}

sub exception_then_await : Tests {
    my $p = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!!' }
    })->then(sub {
        my ($value) = @_;
        #
    }, sub {
        my ($reason) = @_;
        return { reason => $reason };
    });
    is_deeply $p->await(), { reason => { message => 'oh my god!!!' } };
}

sub exception_catch_then_await : Tests {
    my $p = Promise::Tiny::AnyEvent->new(sub {
        my ($resolve, $reject) = @_;
        die { message => 'oh my god!!!' }
    })->catch(sub {
        my ($reason) = @_;
        return { recover => 1, reason => $reason };
    })->then(sub {
        my ($value) = @_;
        return $value;
    });
    is_deeply $p->await(), { recover => 1, reason => { message => 'oh my god!!!' } };
}

__PACKAGE__->runtests;
