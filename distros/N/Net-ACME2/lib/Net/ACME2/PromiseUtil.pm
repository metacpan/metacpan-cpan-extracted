package Net::ACME2::PromiseUtil;

use strict;
use warnings;

sub then {
    my ($maybe_promise, $todo_cr) = @_;

    if (UNIVERSAL::can($maybe_promise, 'then')) {
        return $maybe_promise->then($todo_cr);
    }

    return $todo_cr->($maybe_promise);
}

sub do_then_catch {
    my ($try_cr, $then_cr, $catch_cr) = @_;

    my $maybe_promise;

    my $old_err = $@;
    my $ok = eval { $maybe_promise = $try_cr->(); 1 };
    my  $err = $@;
    $@ = $old_err;

    if ($ok) {
        if (UNIVERSAL::can($maybe_promise, 'then')) {
            return $maybe_promise->then($then_cr, $catch_cr);
        }
        else {
            return $then_cr->($maybe_promise);
        }
    }

    return $catch_cr->($err);
}

1;
