package Shared::Arena::Scoreboard;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Scoreboard - one row per worker, published live

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(name => 'app', size => 2 * 1024 * 1024);
    my $sb    = $arena->scoreboard('workers',
                                   fields => ['inflight', 'served'],
                                   slots  => 256);

    # in each worker, after the fork
    $sb->take;
    $sb->update(inflight => $n, served => $total, status => "GET $path");

    # in the supervisor, or a /status endpoint
    for my $row ($sb->all) {
        printf "pid %-6d %-4s in=%d served=%d  %s\n",
            $row->{pid}, ($row->{alive} ? 'up' : 'DEAD'),
            $row->{inflight}, $row->{served}, $row->{status};
    }

=head1 DESCRIPTION

Every other shared table in this dist has many writers to one structure, and
pays a lock to keep them from tearing each other's writes. A scoreboard is the
inverse: each worker owns B<one row> and is its only writer, so an update takes
no lock, and a reader - a supervisor, a status page - reads every row in one
pass.

So there is no write contention at all. This is Apache's scoreboard, for a
fork-shared pool: a live per-worker view - how many requests each worker has
in flight, how many it has served, what it is doing right now - that a
supervisor reads straight out of memory instead of collecting over a pipe or a
stats socket per worker.

Get one from C<< $arena->scoreboard($name) >>. The C<fields> name the gauge
columns and are set once by whoever creates the board; a later caller names the
same ones or inherits them, and inherits C<slots> too, so a worker does not
have to know how big the board is.

=head2 A coherent snapshot, and still no lock

A reader wants a row's fields B<together>: the in-flight count and the status
line as of one instant, not the count from before an update and the string from
after. The single writer marks the row while it writes and a reader that catches
it mid-write retries - the ring's two-word discipline, but with exactly one
writer, so no lock is needed on either side.

=head2 A dead worker's row is reclaimed, not leaked

A row records its owner's pid. A worker that dies leaves its row occupied and
stale; L</all> shows it with C<< alive => 0 >> rather than as current, and the
next worker that starts and needs a row reclaims one whose owner is gone. A
worker that died B<mid-update> - its row caught permanently half-written - is
skipped by a reader rather than shown torn.

=head1 METHODS

=head2 take

    my $row = $sb->take;

Claim a row for this process, reclaiming a dead worker's row if the board is
full. Returns the row index, or C<undef> when every row belongs to a live
worker. Idempotent - call it again in the same process and it returns the row
you already hold. Call it once at worker start, after the fork.

C<update>, C<incr> and C<status> call C<take> for you if you have not, so in
practice you can just start writing.

=head2 update

    $sb->update(inflight => 3, served => 128, status => 'GET /x');

Set gauge fields by name and/or the status line, in B<one coherent update>: a
reader sees them all as of one instant. An unknown field name is a croak, not a
silent no-op - a typo'd column is a bug. This is the call to put on the request
path.

=head2 incr

    $sb->incr(served => 1, bytes => $n);

Add to gauge fields, coherently. Steps may be negative.

=head2 status

    $sb->status('idle');

Just the status line.

=head2 all

    my @rows = $sb->all;

The whole board, as a list of hashrefs in row order, one per live row:

    { row, pid, epoch, updated, alive, status, <field> => <value>, ... }

C<updated> is the wall-clock millisecond of the row's last write; C<alive> is
whether the owner is still running - a dead worker's row is shown, not dropped,
so you can see who died. A row whose writer died mid-update is left out.

=head2 stats

    my %s = $sb->stats;    # slots, live, alive

C<live> is rows claimed, C<alive> is rows whose owner is still running; the
difference is workers that have died but not yet been reclaimed.

=head2 fields, slots, mine

    my @cols = $sb->fields;    # the gauge column names, in order
    my $cap  = $sb->slots;     # how many workers the board holds
    my $row  = $sb->mine;      # our row index, or undef

=head1 CAVEATS

A board holds a fixed number of rows and a fixed set of up to eight gauge
fields; both are set when it is created and do not grow. Size C<slots> for the
largest pool you will run.

A row belongs to the B<process>, not the handle. A handle going out of scope
leaves the row where it is - a supervisor keeps reading it until the process
exits, and a successor reclaims it then.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Map>, L<Shared::Arena::Lease>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
