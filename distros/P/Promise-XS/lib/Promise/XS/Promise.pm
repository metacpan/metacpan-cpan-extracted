package Promise::XS::Promise;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Promise::XS::Promise - promise object

=head1 SYNOPSIS

See L<Promise::XS>.

=head1 DESCRIPTION

This is L<Promise::XS>’s actual promise object class. It implements
these methods:

=over

=item * C<then()>

=item * C<catch()>

=item * C<finally()>

=back

… which behave as they normally do in promise implementations.

Additionally, C<all()> and C<race()> may be used, thus:

    my $p3 = Promise::XS::Promise->all( $p1, $p2, .. );
    my $p3 = Promise::XS::Promise->race( $p1, $p2, .. );

… or, just:

    my $p3 = ref($p1)->all( $p1, $p2, .. );
    my $p3 = ref($p1)->race( $p1, $p2, .. );

… or even:

    my $p3 = $p1->all( $p1, $p2, .. );
    my $p3 = $p1->race( $p1, $p2, .. );

(Note the repetition of $p1 in these last examples!)

=head1 NOTES

Subclassing this class won’t work because the above-named methods always
return instances of (exactly) this class. That may change eventually,
but for now this is what’s what.

=cut

# Lifted from AnyEvent::XSPromises
sub all {
    my $remaining= @_ - 1;
    my @values;
    my $failed= 0;
    my $then_what= Promise::XS::Deferred::create();
    my $pending= 1;
    my $i= 0;

    my $promise = $then_what->promise();

    my $reject_now = sub {
        if (!$failed++) {
            $pending= 0;
            $then_what->reject(@_);
            undef $then_what;   # proactively eliminate references
        }
    };

    for my $p (@_[1 .. $#_]) {
        my $i = $i++;

        $p->then(
            sub {
                $values[$i]= \@_;
                if ((--$remaining) == 0) {
                    $pending= 0;
                    $then_what->resolve(@values);
                    undef $then_what;   # proactively eliminate references
                }
            },
            $reject_now,
        );
    }
    if (!$remaining && $pending) {
        $then_what->resolve(@values);
    }
    return $promise;
}

# Lifted from Promise::ES6
sub race {
    my $deferred = Promise::XS::Deferred::create();

    my $is_done;

    my $promise = $deferred->promise();

    my $on_resolve_cr = sub {
        return if $is_done;
        $is_done = 1;

        $deferred->resolve(@_);

        # Proactively eliminate references:
        undef $deferred;
    };

    my $on_reject_cr = sub {
        return if $is_done;
        $is_done = 1;

        $deferred->reject(@_);

        # Proactively eliminate references:
        undef $deferred;
    };

    for my $given_promise (@_[1 .. $#_]) {
        $given_promise->then($on_resolve_cr, $on_reject_cr);
    }

    return $promise;
}

sub _warn_unhandled {
    my (@reasons) = @_;

    my $class = __PACKAGE__;

    if (1 == @reasons) {
        warn "$class: Unhandled rejection: $reasons[0]\n";
    }
    else {
        my $total = 0 + @reasons;

        for my $i ( 0 .. $#reasons ) {
            my $num = 1 + $i;

            warn "$class: Unhandled rejection ($num of $total): $reasons[$i]\n";
        }
    }
}

#----------------------------------------------------------------------
# Future::AsyncAwait interface
#----------------------------------------------------------------------

#sub AWAIT_ON_READY {
#    $_[0]->finally($_[1])->catch(\&AWAIT_CHAIN_CANCEL);
#}

1;
