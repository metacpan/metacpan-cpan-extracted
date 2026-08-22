package PAGI::FastAPI::Middleware::ExceptionHandler;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.5');
our $AUTHORITY = 'cpan:MANWAR';

use Future::AsyncAwait;
use Scalar::Util qw(blessed);

# Built on the documented add_middleware($coderef) extension point, the
# same mechanism eg/rate_limit_demo.pl uses to wrap the app-wide rate
# limiter.
#
# CONTRACT NOTE: the framework's own dependency-failure convention (see
# PAGI::FastAPI's _register_route dependency loop) is "set $c->status(>=400)
# and return a body hash" rather than throwing a typed exception object. If
# your dependencies/handlers already follow that convention, you may not
# need this at all. This module exists for the case where you (or a
# database layer, or a third-party module you're calling into) throw real
# Perl exceptions, blessed objects or plain strings via die, and you want
# FastAPI-style "register a handler per exception class" dispatch instead
# of wrapping every handler in its own eval.

class PAGI::FastAPI::Middleware::ExceptionHandler {
    field $handlers        :param = {};
    field $default_handler :param = undef;

    async method handle ($c, $next) {
        my $res = eval { return await $next->($c) };
        if (my $err = $@) {
            return await $self->_dispatch($err, $c);
        }
        return $res;
    }

    async method _dispatch ($err, $c) {
        my $class = blessed($err);

        if (defined $class) {
            # Walk the registered handler classes, most-specific first:
            # exact class match wins; otherwise the first registered class
            # that $err->isa(...) matches. Registration order among isa()
            # matches is significant, register more specific parent classes
            # AFTER more general ones if that matters to you, since
            # the first isa() match found wins.
            if (my $h = $handlers->{$class}) {
                return await $h->($err, $c);
            }
            for my $registered_class (keys %$handlers) {
                if ($err->isa($registered_class)) {
                    return await $handlers->{$registered_class}->($err, $c);
                }
            }
        }
        else {
            # Plain string exception (die "some message\n"), only a handler
            # explicitly registered under the empty-string / '' key or the
            # default handler can catch these, since there's no class to
            # match against.
            if (my $h = $handlers->{''}) {
                return await $h->($err, $c);
            }
        }

        if ($default_handler) {
            return await $default_handler->($err, $c);
        }

        # No handler matched and no default configured, re-throw so the
        # failure isn't silently swallowed. Whatever wraps THIS middleware
        # (or the PAGI runtime itself) is responsible for turning an
        # unhandled die into a 500, same as if this middleware weren't
        # installed at all.
        die $err;
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Middleware::ExceptionHandler - Typed Exception-to-Handler Dispatch for PAGI::FastAPI

=head1 VERSION

Version v1.2.5

=head1 SYNOPSIS

    use PAGI::FastAPI::Middleware::ExceptionHandler;

    package My::Errors::NotFound;
    sub new    ($class, %args) { return bless { %args }, $class }
    sub message { return $_[0]->{message} // 'Not Found' }

    package main;

    my $handler = PAGI::FastAPI::Middleware::ExceptionHandler->new(
        handlers => {
            'My::Errors::NotFound' => async sub ($err, $c) {
                $c->status(404);
                return { detail => $err->message };
            },
        },
        default_handler => async sub ($err, $c) {
            $c->status(500);
            return { detail => 'Internal Server Error' };
        },
    );

    $app->add_middleware(async sub ($c, $next) {
        return await $handler->handle($c, $next);
    });

    $app->get('/items/{id}',
        handler => async sub ($c) {
            my $item = My::DB->find($c->path_param('id'))
                or die My::Errors::NotFound->new(message => 'No such item');
            return $item;
        }
    );

=head1 DESCRIPTION

Wraps the rest of the middleware/handler chain in an C<eval>, and dispatches
any thrown exception to a registered handler based on the exception's class
(via C<blessed()> and C<isa()>), falling back to a C<default_handler> if
given, or re-throwing if nothing matches.

This intentionally mirrors Python FastAPI's C<@app.exception_handler(SomeError)>
pattern, adapted to a middleware + registry shape that fits
L<PAGI::FastAPI>'s existing C<add_middleware> extension point rather than
requiring any change to route registration or dispatch internals.

B<Relationship to core's own error convention:> C<PAGI::FastAPI>'s built-in
dependency mechanism already has its own failure convention, a dependency
sets C<< $c->status(>=400) >> and returns a body hash, which
C<PAGI::FastAPI> checks for directly without any exception being thrown at
all. This module doesn't replace that; it's for the separate case of actual
Perl exceptions (C<die>) escaping a handler or a dependency, which core has
no built-in registry for.

=head1 METHODS

=head2 C<new(%options)>

=over 4

=item * C<handlers> - HashRef mapping exception class name (string) to a
coderef of C<< async sub ($exception, $c) { ... } >>. The empty string key
C<''> catches plain (non-blessed) exceptions, e.g. from C<die "message">.

=item * C<default_handler> - (Optional) Coderef of the same shape, used when
no registered class matches. If omitted, unmatched exceptions are re-thrown.

=back

=head2 C<handle($c, $next)>

Call this from an C<add_middleware> wrapper, exactly as
C<eg/rate_limit_demo.pl> does for C<PAGI::FastAPI::Middleware::RateLimit>.

=head1 CAVEATS

Handler lookup for subclasses (via C<isa()>) iterates the registered
handlers in hash order when there's no exact class match, so if an exception
could match more than one registered I<parent> class, which one wins is not
guaranteed. Register an exact match for any exception class where this
ambiguity matters.

=head1 SEE ALSO

L<PAGI::FastAPI::Middleware::RateLimit>, L<PAGI::FastAPI::Middleware::BotProtection>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::Middleware::ExceptionHandler

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::Middleware::ExceptionHandler
