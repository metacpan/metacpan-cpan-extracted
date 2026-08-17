package Punk::Command::Queue;

use 5.010;
use strict;
use warnings;
use Punk::Command ();
use Punk::Queue::Command ();

our $VERSION = '0.04';

# The seam bin/punk probes on an unknown command: loading this module is the
# registration. `punk queue X ...` forwards raw argv to the punk-queue
# dispatcher, so the two spellings are the same CLI - one option surface,
# one help, byte-identical output.

Punk::Command->register(queue => {
    abstract => 'the job queue (punk-queue)',
    display  => 'queue <command>',
    usage    => '<command> [options]',
    desc     => 'Everything bin/punk-queue does - worker, enqueue, jobs, '
              . "stats, crons, locks,\nmigrate and the rest - reached as a "
              . 'punk subcommand.',
    raw      => 1,
    code     => sub {
        my (undef, @argv) = @_;
        return Punk::Queue::Command::main(@argv);
    },
}, __PACKAGE__) if Punk::Command->can('register');

Punk::Command->register_doctor('Punk::Queue' => sub {
    require Punk::Queue;
    return (1, $Punk::Queue::VERSION);
}, __PACKAGE__) if Punk::Command->can('register_doctor');

1;

__END__

=head1 NAME

Punk::Command::Queue - `punk queue ...`, the punk-queue CLI as a subcommand

=head1 SYNOPSIS

    punk queue stats --dsn dbi:SQLite:queue.db
    punk queue worker --app bin/queue.pl -j 2
    punk queue help

=head1 DESCRIPTION

Loading this module registers C<queue> with L<Punk::Command>'s registry -
which is exactly what F<bin/punk> does on an unknown command, so
C<punk queue ...> works wherever Punk::Queue is installed, with no
configuration. Arguments are forwarded verbatim to
L<Punk::Queue::Command>, so C<punk queue X> and C<punk-queue X> are one
CLI: same options, same help, same output, same exit codes.

A C<Punk::Queue> row also joins C<punk doctor>'s plugin section.

=head1 SEE ALSO

L<Punk::Queue>, L<Punk::Queue::Command>, L<Punk::Command>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
