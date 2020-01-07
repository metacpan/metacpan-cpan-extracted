package Promise::ES6;

use strict;
use warnings;

our $VERSION = '0.17';

=encoding utf-8

=head1 NAME

Promise::ES6 - ES6-style promises in Perl

=head1 SYNOPSIS

    my $promise = Promise::ES6->new( sub {
        my ($resolve_cr, $reject_cr) = @_;

        # ..
    } );

    my $promise2 = $promise->then( sub { .. }, sub { .. } );

    my $promise3 = $promise->catch( sub { .. } );

    my $promise4 = $promise->finally( sub { .. } );

    my $resolved = Promise::ES6->resolve(5);
    my $rejected = Promise::ES6->reject('nono');

    my $all_promise = Promise::ES6->all( \@promises );

    my $race_promise = Promise::ES6->race( \@promises );

=head1 DESCRIPTION

This module provides a Perl implementation of L<promises|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>, a useful pattern
for coordinating asynchronous tasks.

Unlike most other promise implementations on CPAN, this module
mimics ECMAScript 6’s L<Promise|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise>
interface. As the SYNOPSIS above shows, you can thus use patterns from
JavaScript in Perl with only minimal changes needed to accommodate language
syntax.

This is a rewrite of an earlier module, L<Promise::Tiny>. It fixes several
bugs and superfluous dependencies in the original.

=head1 INTERFACE NOTES

=over

=item * Promise resolutions and rejections accept exactly one argument,
not a list.

=item * Unhandled rejections are reported via C<warn()>. (See below
for details.)

=item * The Promises/A+ test suite avoids testing the case where an “executor”
function’s resolve callback itself receives another promise, e.g.:

    my $p = Promise::ES6->new( sub ($res) {
        $res->( Promise::ES6->resolve(123) );
    } );

What will $p’s resolution value be? 123, or the promise that wraps it?

This module favors conformity with the ES6 standard, which
L<indicates intent|https://www.ecma-international.org/ecma-262/6.0/#sec-promise-executor> that $p’s resolution value be 123.

=back

=head1 COMPATIBILITY

Right now this doesn’t try for interoperability with other promise
classes. If that’s something you want, make a feature request.

See L<Promise::ES6::Future> if you need to interact with L<Future>.

=head1 UNHANDLED REJECTIONS

As of version 0.05, unhandled rejections prompt a warning I<only> if one
of the following is true:

=over

=item 1) The unhandled rejection happens outside of the constructor.

=item 2) The unhandled rejection happens via an uncaught exception
(even within the constructor).

=back

=head1 SYNCHRONOUS OPERATION

In JavaScript, the following …

    Promise.resolve().then( () => console.log(1) );
    console.log(2);

… will log C<2> then C<1> because JavaScript’s C<then()> defers execution
of its callbacks until the end of the current iteration through JavaScript’s
event loop.

Perl, of course, has no built-in event loop. This module’s C<then()> method,
thus, when called on a promise that is already
“settled” (i.e., not pending), will run the appropriate callback
I<immediately>. That means that this:

    Promise::ES6->resolve(0)->then( sub { print 1 } );
    print 2;

… will print C<12> instead of C<21>.

This is an intentional divergence from
L<the Promises/A+ specification|https://promisesaplus.com/#point-34>.
A key advantage of this design is that Promise::ES6 instances can abstract
over whether a given function works synchronously or asynchronously.

If you want a Promises/A+-compliant implementation, look at
L<Promise::ES6::IOAsync>, L<Promise::ES6::Mojo>,
L<Promise::ES6::AnyEvent>, or one of the alternatives
that that module’s documentation suggests.

=head1 CANCELLATION

Promises have never provided a standardized solution for cancellation—i.e.,
aborting an in-process operation. So, if you need this functionality, you’ll
have to implement it yourself. Two ways of doing this are:

=over

=item * Subclass Promise::ES6 and provide cancellation logic in that
subclass. See L<DNS::Unbound::AsyncQuery>’s implementation for an
example of this.

=item * Implement the cancellation on a request object that your
“promise-creator” also consumes. This is probably the more straightforward
approach but requires that there
be some object or ID besides the promise that uniquely identifies the action
to be canceled. See L<Net::Curl::Promiser> for an example of this approach.

=back

You’ll need to decide if it makes more sense for your application to leave
a canceled query in the “pending” state or to resolve or reject it.
All things being equal, I feel the first approach is the most intuitive.

=head1 MEMORY LEAKS

It’s easy to create inadvertent memory leaks using promises in Perl.
Here are a few “pointers” (heh) to bear in mind:

=over

=item * As of version 0.07, any Promise::ES6 instances that are created while
C<$Promise::ES6::DETECT_MEMORY_LEAKS> is set to a truthy value are
“leak-detect-enabled”, which means that if they survive until their original
process’s global destruction, a warning is triggered.

=item * If your application needs recursive promises (e.g., to poll
iteratively for completion of a task), the C<current_sub> feature (i.e.,
C<__SUB__>) may help you avoid memory leaks. In Perl versions that don’t
support this feature you can imitate it thus:

    use constant _has_current_sub => $^V ge v5.16.0;

    use if _has_current_sub(), feature => 'current_sub';

    my $cb;
    $cb = sub {
        my $current_sub = do {
            no strict 'subs';
            _has_current_sub() ? __SUB__ : eval '$cb';
        };
    }

Of course, it’s better if you can avoid doing that. :)

=item * Garbage collection before Perl 5.18 seems to have been buggy.
If you work with such versions and end up chasing leaks,
try manually deleting as many references/closures as possible. See
F<t/race_success.t> for a notated example.

You may also (counterintuitively, IMO) find that this:

    my ($resolve, $reject);

    my $promise = Promise::ES6->new( sub { ($resolve, $reject) = @_ } );

    # … etc.

… works better than:

    my $promise = Promise::ES6->new( sub {
        my ($resolve, $reject) = @_;

        # … etc.
    } );

=back

=head1 TODO

Currently rejections will defer until promises are resolved. This makes
no real sense and ought to change. Do not build anything that depends on
this behavior.

=head1 SEE ALSO

If you’re not sure of what promises are, there are several good
introductions to the topic. You might start with
L<this one|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>.

Promise::ES6 serves much the same role as L<Future> but exposes
a standard, minimal, cross-language API rather than a proprietary (large) one.

CPAN contains a number of other modules that implement promises. I think
mine is the nicest :), but YMMV. Enjoy!

=head1 LICENSE & COPYRIGHT

Copyright 2019 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.

=cut

#----------------------------------------------------------------------

our $DETECT_MEMORY_LEAKS;

sub catch { $_[0]->then( undef, $_[1] ) }

sub finally { $_[0]->then( $_[1], $_[1] ) }

sub resolve {
    my ( $class, $value ) = @_;

    $class->new( sub { $_[0]->($value) } );
}

sub reject {
    my ( $class, $reason ) = @_;

    $class->new( sub { $_[1]->($reason) } );
}

sub all {
    my ( $class, $iterable ) = @_;
    my @promises = map { UNIVERSAL::isa( $_, __PACKAGE__ ) ? $_ : $class->resolve($_) } @$iterable;

    my @values;

    return $class->new(
        sub {
            my ( $resolve, $reject ) = @_;
            my $unresolved_size = scalar(@promises);

            my $settled;

            if ($unresolved_size) {
                my $p = 0;

                my $on_reject_cr = sub {

                    # Needed because we might get multiple failures:
                    return if $settled;

                    $settled = 1;
                    $reject->(@_);
                };

                for my $promise (@promises) {
                    last if $settled;

                    my $p = $p++;

                    $promise->then(
                        sub {
                            return if $settled;

                            $values[$p] = $_[0];

                            $unresolved_size--;
                            return if $unresolved_size > 0;

                            $settled = 1;
                            $resolve->( \@values );
                        },
                        $on_reject_cr,
                    );
                }
            }
            else {
                $resolve->( [] );
            }
        }
    );
}

sub race {
    my ( $class, $iterable ) = @_;
    my @promises = map { UNIVERSAL::isa( $_, __PACKAGE__ ) ? $_ : $class->resolve($_) } @$iterable;

    my ( $resolve, $reject );

    # Perl 5.16 and earlier leak memory when the callbacks are handled
    # inside the closure here.
    my $new = $class->new(
        sub {
            ( $resolve, $reject ) = @_;
        }
    );

    my $is_done;

    my $on_resolve_cr = sub {
        return if $is_done;
        $is_done = 1;

        $resolve->( $_[0] );

        # Proactively eliminate references:
        $resolve = $reject = undef;
    };

    my $on_reject_cr = sub {
        return if $is_done;
        $is_done = 1;

        $reject->( $_[0] );

        # Proactively eliminate references:
        $resolve = $reject = undef;
    };

    for my $promise (@promises) {
        last if $is_done;

        $promise->then( $on_resolve_cr, $on_reject_cr );
    }

    return $new;
}

#----------------------------------------------------------------------

my $loaded_backend;

BEGIN {
    # Put this block at the end so that the backend module
    # can override any of the above.

    return if $loaded_backend;

    $loaded_backend = 1;

    # These don’t exist yet but will:
    if (0 && !$ENV{'PROMISE_ES6_PP'} && eval { require Promise::ES6::XS }) {
        require Promise::ES6::Backend::XS;
    }

    # Fall back to pure Perl:
    else {
        require Promise::ES6::Backend::PP;
    }
}

1;
