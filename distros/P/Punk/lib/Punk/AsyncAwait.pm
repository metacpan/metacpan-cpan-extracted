package Punk::AsyncAwait;

# Future::AsyncAwait needs 5.16; Punk itself claims 5.10. Nothing in Punk
# loads this module, so a 5.10 perl installs and runs Punk exactly as before
# and only an application that asks for the keywords pays the higher floor.
use 5.016;
use strict;
use warnings;

our $VERSION = '0.49';

use Punk::Future ();        # the AWAIT_* methods live in Punk's XS, and a
                            # controller may never have loaded Punk itself
use Future::AsyncAwait ();

# `async` and `await` are parser keywords, not subs - they need a real keyword
# plugin, which is what Future::AsyncAwait installs through the lexical hints
# hash. Forwarding its import from ours installs them into whatever scope is
# compiling when the `use` line is reached, which is the caller's file.
#
# The default future class goes first so a caller's own choice wins: the hint
# is assigned once per occurrence, last one through.
sub import {
    my $class = shift;
    Future::AsyncAwait->import( future_class => 'Punk::Future', @_ );
}

sub unimport {
    my $class = shift;
    Future::AsyncAwait->unimport(@_);
}

1;

__END__

=head1 NAME

Punk::AsyncAwait - async and await in Punk apps, controllers and models

=head1 SYNOPSIS

The keywords are lexical, so every file that uses them says so. That is three
files, not one:

    package MyApp;                          # the app
    use Punk;
    use Punk::AsyncAwait;

    get '/rooms' => async sub {
        my ($c) = @_;
        my $rooms = await $c->model('Message')->rooms;
        return $c->json({ rooms => $rooms });
    };

    package MyApp::Controller::API::Message;    # a controller
    use Punk::Controller;
    use Punk::AsyncAwait;

    async sub listRooms {
        my ($c) = @_;
        my $rooms = await $c->model('Message')->rooms;
        $_->{connected} = MyApp::Bus::connected($_->{room}) for @$rooms;
        return { rooms => $rooms };
    }

    package MyApp::Model::Message;              # a model
    use Punk::Model;
    use Punk::AsyncAwait;

=head1 DESCRIPTION

Punk hands back a L<Punk::Future> from anything asynchronous, and its
dispatcher already awaits a future a handler returns. This module adds the
other half: C<await> inside the handler, so a chain of C<then> callbacks
becomes straight-line code.

    # before
    return $c->model('Book')->search({})->then(sub {
        my ($page) = @_;
        $c->render('book/list', { books => $page->{rows} });
    });

    # after
    my $page = await $c->model('Book')->search({});
    return $c->render('book/list', { books => $page->{rows} });

There is nothing to configure and no plugin to register. The keywords come
from L<Future::AsyncAwait>; this module is the one line that points them at
Punk's own future class so an C<async sub> that never suspends does not drag
in CPAN L<Future>, which Punk only recommends.

=head1 IMPORT

    use Punk::AsyncAwait;
    use Punk::AsyncAwait future_class => 'Future';   # override
    no Punk::AsyncAwait;                             # off for the rest of the scope

Arguments pass through to L<Future::AsyncAwait>, after a default of
C<< future_class => 'Punk::Future' >> that your own C<future_class> overrides.
C<< :experimental(cancel) >> and friends work as they do there.

=head1 WHAT TO EXPECT

=head2 It is per-file

C<use Punk::AsyncAwait> in the application class does nothing for your
controllers. The keywords are lexically scoped, like C<strict>: every file
that writes C<async> or C<await> imports them itself.

=head2 Awaiting off the loop

An C<async sub> that suspends needs something to resume it. On a Hyperman
worker that is the loop. Anywhere else there is nothing to drive the future,
and the await dies with

    Punk::Future: await on a pending future with no event loop to drive it

which is the deadlock reported rather than hung. It means the handler
suspended on a server that cannot resume it: run under C<hyperman>, or do not
suspend. Note the message names the future, not the server.

=head2 C<< $c->await >> is a different thing

L<Punk::Context>'s C<< $c->await($future) >> blocks and pumps the loop; the
C<await> keyword suspends the enclosing C<async sub> and returns to it later.
Both are legal in the same scope and they do not collide - the method is a
method call, the keyword is a keyword. Inside an C<async sub>, prefer the
keyword.

=head2 Awaiting a future from elsewhere

Awaiting a future of another class - a L<Fetch::Future>, a L<DBIx::Loop>
future, a CPAN L<Future> - is fine, and the C<async sub> then returns a future
of I<that> class rather than a Punk::Future. Punk's dispatcher accepts any
future-compatible value, so a handler still works either way.

=head2 Abandoned futures

A suspended C<async sub> holds the future it is waiting on, which holds the
reaction that will resume it. A future that is never settled therefore keeps
the whole chain alive. Cancel a future you have given up on, rather than
dropping it.

=head1 SEE ALSO

L<Punk::Future>, L<Future::AsyncAwait>, L<Punk::Controller>, L<Punk::Model>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
