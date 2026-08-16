package Punk::Logger;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.12';

1;

__END__

=head1 NAME

Punk::Logger - a level-based logger

=head1 SYNOPSIS

    get '/books' => sub {
        my ($c) = @_;
        $c->log->info('listing books');
        my @books = eval { ... } or $c->log->error('db down: %s', $@);
        $c->json(\@books);
    };

    # configure (optional - it works with none)
    logging level => 'debug', format => 'json';

=head1 DESCRIPTION

C<< $c->log >> is a request logger (it tags each line with the request method
and path) and C<< $app->log >> the application logger. Both offer C<debug>,
C<info>, C<warn>, C<error> and C<fatal> - a single argument is the message,
several are C<sprintf($format, @args)> - and a generic C<< log($level, ... ) >>.
Each returns the logger, so calls chain.

Output goes to the server's C<psgix.logger> when one is provided (the PSGI
logging convention - the server owns routing and formatting), and otherwise to
C<STDERR> as C<< [<ISO-8601 UTC>] [<level>] <method> <path> - <message> >>. It
works with no configuration.

A call below the configured level does no formatting at all, and a failing sink
never takes the request down.

=head1 CONFIGURATION

    logging
        level  => 'info',      # debug < info < warn < error < fatal
        format => 'plain',     # or 'json' - one object per line
        to     => \*STDOUT;    # a filehandle or coderef; default STDERR

Also from C<punk.yml> under a C<logging:> block. C<STDERR> is the deliberate
default (let the platform route it); point C<to> at a coderef or filehandle, or
provide a C<psgix.logger>, for anything else.

=head1 METHODS

=head2 debug / info / warn / error / fatal ($message | $format, @args)

Log at that level. Chainable.

=head2 log($level, $message | $format, @args)

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
