package Punk::Queue::Cron;

use 5.010;
use strict;
use warnings;
use Punk::Queue ();

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::Queue::Cron - the cron expression parser and occurrence walk

=head1 SYNOPSIS

    use Punk::Queue;

    # validate at boot - croaks with the reason, names the spec
    Punk::Queue::Cron->check('0 3 * * *');
    Punk::Queue::Cron->check('30 2 * * *', 'local');

    # the next occurrence strictly after an epoch, or undef
    my $at = Punk::Queue::Cron->next_after('*/15 * * * *', time);
    my $ny = Punk::Queue::Cron->next_after('0 3 * * *', time, '+0530');

    # from the shell, no database required:
    #   punk-queue cron next '*/15 * * * *' --count 10

=head1 DESCRIPTION

Five fields - minute, hour, day-of-month, month, day-of-week - compiled
once in C into bitmasks, then walked structurally (months skipped by
month, days by day, hours by hour) to the next occurrence. The walk is
pure arithmetic over epoch seconds; nothing here touches the database.
The scheduler that turns occurrences into jobs lives in the supervisor
and is documented in L<Punk::Queue>.

=head2 Supported syntax

C<*>, ranges C<a-b>, steps C<*/n> and C<a-b/n>, lists C<a,b,c>,
case-insensitive three-letter month and day names (C<jan>, C<mon>),
day-of-week 0-7 with both 0 and 7 meaning Sunday, the C<@yearly>,
C<@annually>, C<@monthly>, C<@weekly>, C<@daily>, C<@midnight> and
C<@hourly> aliases, and C<@every E<lt>nE<gt>(s|m|h|d)> - a plain
interval from the last occurrence, not a wall-clock grid.

Deliberately excluded, and rejected by name rather than mis-parsed:
C<L>, C<W>, C<#>, C<?>, and second or year fields.

=head2 The vixie day rule

When BOTH day fields are restricted, a day matching EITHER fires
(C<0 12 8 * 0> runs on the 8th AND on Sundays). When only one is
restricted, it alone gates. This is the single most common cron
implementation bug; it is implemented faithfully and tested by name.

=head2 Unmatchable expressions

An expression with no occurrence within five years (C<0 0 30 2 *>)
croaks at C<check> - and therefore at boot, at C<upsert_cron>, and at
the C<cron> keyword - instead of becoming a cron that silently never
fires.

=head2 Timezones

C<tz> is C<UTC> (the default), C<local>, or a fixed C<+HHMM>/C<-HHMM>
offset. There is no timezone database: UTC and fixed offsets use bundled
civil-date arithmetic; only C<local> touches libc, because only C<local>
has DST. The DST consequences, stated plainly: an occurrence in the
spring-forward skipped hour does not fire that day; in the fall-back
doubled hour a pinned time fires once, at the first (DST) instance.

=head1 METHODS

=head2 check

    Punk::Queue::Cron->check($expr);
    Punk::Queue::Cron->check($expr, $tz);

Parses and validates. Croaks with the reason - bad field, unsupported
token by name, unknown alias, bad tz, or an expression that can never
fire. Returns true. Every path that stores an expression calls this.

=head2 next_after

    my $epoch = Punk::Queue::Cron->next_after($expr, $from);
    my $epoch = Punk::Queue::Cron->next_after($expr, $from, $tz);

The next occurrence strictly after epoch C<$from>, as an epoch, or undef
when none exists within the five-year horizon. C<$from> itself is never
returned: feeding a result back in walks the schedule.

=head1 SEE ALSO

L<Punk::Queue> for the scheduler that fires these occurrences,
L<Punk::Plugin::Queue> for the C<cron> keyword, and the
C<punk-queue crons> and C<punk-queue cron> subcommands.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=cut
