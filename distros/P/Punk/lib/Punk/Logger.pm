package Punk::Logger;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.27';

1;

__END__

=head1 NAME

Punk::Logger - a level-based logger

=head1 SYNOPSIS

    get '/books' => sub {
        my ($c) = @_;
        $c->log->info('listing books');
        my @books = eval { ... } or $c->log->error('db down: %s', $@);

        # or as a record: fields, with `message` as the message
        $c->log->info({ message => 'listing books',
                        books => scalar @books, user => $c->auth_id });

        $c->json(\@books);
    };

    # configure (optional - it works with none)
    logging level => 'debug', format => 'json';

=head1 DESCRIPTION

C<< $c->log >> is a request logger (it tags each line with the request method
and path) and C<< $app->log >> the application logger. Both offer C<debug>,
C<info>, C<warn>, C<error> and C<fatal> - a single argument is the message,
several are C<sprintf($format, @args)>, and a lone unblessed hashref is a
L</RECORDS> - and a generic C<< log($level, ... ) >>. Each returns the logger,
so calls chain.

Output goes to the server's C<psgix.logger> when one is provided (the PSGI
logging convention - the server owns routing and formatting), and otherwise to
C<STDERR> as C<< [<ISO-8601 UTC>] [<level>] <method> <path> - <message> >>. It
works with no configuration.

A call below the configured level does no formatting at all - the level is read
before the arguments are touched, so C<< $c->log->debug('%s', $expensive) >>
costs one comparison in an app running at C<info> - and a failing sink never
takes the request down.

=head1 RECORDS

A lone unblessed hashref is a record rather than a message. Its C<message> key
is the message; every other key is a field.

    $c->log->info({ message => 'listing books', books => 12, user => 7 });

Under C<< format => 'json' >> the fields are merged into the object, which is
the reason that format exists:

    {"time":"...","level":"info","message":"listing books","books":12,"user":7}

Under C<plain>, and in the message handed to a C<psgix.logger>, they are
rendered after the message as logfmt pairs, sorted by key:

    [2026-08-18T10:00:00Z] [info] GET /books - listing books books=12 user=7

Sorted because perl's hash order is randomised per process, and a log line
that reorders itself between runs is one nobody can diff, grep or test.

A value is quoted when it is empty or holds a space, an C<=>, a C<"> or a
control character; a newline or carriage return inside one is escaped, so a
value can never split a line into two. A key that would break the line the
same way has those bytes replaced with underscores, because
C<< { %$from_the_client } >> is an ordinary thing to write. An C<undef> field
renders as a bare C<key=>. A field holding a reference is rendered as compact
JSON.

=head2 Reserved keys

C<time>, C<level>, C<message>, C<method>, C<path> and C<request_id> belong to
the logger. A field carrying one of those names is dropped rather than merged,
in every format: a field called C<level> must not be able to forge a line's
severity, and a reader has to be able to trust that those six mean what the
logger says they mean.

=head2 A blessed reference is a message

Only an B<unblessed> hashref is a record. An object is a message, however it is
built - one with an overloaded C<""> is an ordinary thing to log, and dumping
its guts as fields instead would silently change what an existing call means.

=head2 Values a JSON encoder refuses

A field holding a code reference, a glob or a regexp - at any depth - is
replaced by its stringification rather than being encoded. A logger that took
the request down because somebody logged a callback would be a worse bug than
the one it was helping to find.

=head1 CONFIGURATION

    logging
        level  => 'info',      # debug < info < warn < error < fatal
        format => 'plain',     # or 'json' - one object per line
        to     => \*STDOUT;    # a filehandle or coderef; default STDERR

Also from C<punk.yml> under a C<logging:> block. C<STDERR> is the deliberate
default (let the platform route it); point C<to> at a coderef or filehandle, or
provide a C<psgix.logger>, for anything else.

=head1 METHODS

=head2 debug / info / warn / error / fatal ($message | $format, @args | \%record)

Log at that level. Chainable.

=head2 log($level, $message | $format, @args | \%record)

The level-first form.

=head1 SEE ALSO

L<Punk>, L<Punk::Context/log>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
