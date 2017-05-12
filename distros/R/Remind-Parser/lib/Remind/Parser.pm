package Remind::Parser;

use strict;
use warnings;

use vars qw($VERSION);

use Date::DayOfWeek qw(dayofweek);

$VERSION = '0.08';

my %dow_cache;

# --- Constructor

sub new {
    my $cls = shift;
    my $self = bless {
        @_,
    }, $cls;
    return $self->_init;
}

sub _init {
    my ($self) = @_;
    # Nothing to do
    return $self;
}

# --- Accessors

sub reminders { scalar(@_) > 1 ? $_[0]->{'reminders'} = $_[1] : $_[0]->{'reminders'} }
sub strict { scalar(@_) > 1 ? $_[0]->{'strict'} = $_[1] : $_[0]->{'strict'} }
sub strip_times { scalar(@_) > 1 ? $_[0]->{'strip_times'} = $_[1] : $_[0]->{'strip_times'} }
sub fill_gaps { scalar(@_) > 1 ? $_[0]->{'fill_gaps'} = $_[1] : $_[0]->{'fill_gaps'} }

# --- Other public methods

sub parse {
    my ($self, $fh) = @_;
    delete $self->{'days'};  # We'll regenerate later if asked
    my ($file, $line, $loc, %file);
    my ($past_header, $all_done);
    my @reminders;
    my %loc2event;
    my %loc2count;
    my $next_event = 1;
    my $start = <$fh>;
    return [] unless defined $start;
    if ($start !~ /^# rem2ps begin$/) {
        die "First line of input is not the proper header: $_"
            if $self->strict;
    }
    while (<$fh>) {
        chomp;
        if ($all_done) { 
            if ($_ !~ /^# rem2ps begin$/ ) {
                die "Spurious input at end of input: $_"
                    if $self->strict;
                last;
            } 
            else { $past_header = 0 ; $all_done = 0 }
        }
        if (/^# fileinfo (\d+) (.+)/) {
            ($line, $file) = ($1, $2);
            $loc = "$file:$line";
            $past_header = 1;
        }
        elsif ($past_header) {
            # We've skipped past the header
            if (/^# rem2ps end$/) {
                # All done
                $all_done = 1;
            }
            else {
                unless (defined $loc) {
                    die "Input does not contain file and line offsets; you must use option -p with remind";
                }
                my ($date, $special, $tag, $duration, $offset, $description) = split / +/, $_, 6;
                my ($year, $month, $day) = split m{[-/]}, $date;
                if ($self->strip_times && $description =~ s/^((\d\d?):(\d\d)([ap]m) )//) {
                    # Strip the time -- but then restore it if it doesn't match
                    #   the offset in minutes
                    my ($stripped, $H, $M, $pm) = ($1, $2, $3, $4 eq 'pm');
                    $description = $stripped . $description
                        unless $offset == _HMpm2min($H, $M, $pm);
                }
                my $event = $loc2event{$loc} ||= $next_event++;
                my $instance = ++$loc2count{$loc};
                my %reminder = (
                    'event'       => $event,
                    'instance'    => $instance,
                    'file'        => $file,
                    'line'        => $line,
                    'year'        => $year  + 0,
                    'month'       => $month + 0,
                    'day'         => $day   + 0,
                    'description' => $description,
                    $tag eq '*'     ? () : ('tag'     => $tag),
                    $special eq '*' ? () : ('special' => $special),
                );
                $reminder{'date'} = _format_date(@reminder{qw(year month day)});
                my ($begin, $end);
                if ($offset eq '*') {
                    # Untimed (whole day) reminder
                    $reminder{'all_day'} = 1;
                }
                else {
                    # Timed reminder
                    my $H = $reminder{'hour'}   = int($offset / 60);
                    my $M = $reminder{'minute'} = $offset % 60;
                    my $S = $reminder{'second'} = 0;
                    if ($duration ne '*') {
                        $reminder{'duration'} = {
                            'hours'   => int($duration / 60),
                            'minutes' => $duration % 60,
                            'seconds' => 0,
                        };
                    }
                }
                push @reminders, _normalize_date(\%reminder);
            }
        }
    }
    return $self->{'reminders'} = \@reminders;
}

sub days {
    my ($self, %args) = @_;
    return $self->{'days'} if $self->{'days'};
    my ($begin_date, $end_date) = @args{qw(begin end)};
    my $reminders = $self->reminders;
    my %date_info;
    _consolidate_reminders($reminders, \%date_info);
    _sort_date_reminders(\%date_info);
    if (exists $args{'fill_gaps'}) {
        _fill_gaps(\%date_info) if $args{'fill_gaps'};
    }
    elsif ($self->fill_gaps) {
        _fill_gaps(\%date_info);
    }
    if (defined $begin_date) {
        foreach (sort keys %date_info) {
            delete $date_info{$_}
                if $_ lt $begin_date;
        }
    }
    if (defined $end_date) {
        foreach (sort keys %date_info) {
            delete $date_info{$_}
                if $_ gt $end_date;
        }
    }
    return $self->{'days'} = [ map { $date_info{$_} } sort keys %date_info ];
}

sub _HMpm2min {
    my ($H, $M, $pm) = @_;
    my $base = $pm ? 12 * 60 : 0;
    $H = 0 if $H == 12;  # 12:XXam --> 00:XXam, 12:XXpm --> 00:XXpm
    return $base + $H * 60 + $M;
}

# -------------------------------- Functions

sub _consolidate_reminders {
    my ($reminders, $date_info) = @_;
    foreach my $r (@$reminders) {
        my ($ymd, $year, $month, $day) = @$r{qw/date year month day/};
        my $info = $date_info->{$ymd} ||= _normalize_date({
            'date'  => $ymd,
            'year'  => $year,
            'month' => $month,
            'day'   => $day,
            'reminders' => [],
        });
        delete $date_info->{$ymd}->{'date_time'};
        push @{ $info->{'reminders'} }, $r;
    }
}

sub _sort_date_reminders {
    my ($date_info) = @_;
    foreach my $ymd (keys %$date_info) {
        my $reminders = $date_info->{$ymd}->{'reminders'};
        # Sort reminders within the date
        @$reminders = sort { $a->{'date_time'} cmp $b->{'date_time'} } @$reminders;
    }
}

sub _fill_gaps {
    my ($date_info) = @_;
    my @dates = sort keys %$date_info;
    my $iter = _iter_dates($dates[0], $dates[-1]);
    while (my $dt = $iter->()) {
        if (!exists $date_info->{$dt}) {
            my ($y, $m, $d) = _parse_date($dt);
            my $ymd = _format_date($y, $m, $d);
            $date_info->{$dt} = _normalize_date({
                'date'      => $ymd,
                'year'      => $y,
                'month'     => $m,
                'day'       => $d,
                'reminders' => [],
            });
            delete $date_info->{$ymd}->{'date_time'};
        }
    }
}

BEGIN {
    # Adapted from Date::ISO8601 by Zefram
    my @days_in_month = (undef, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    sub _is_leap_year {
        my ($y) = @_;
        return $y % 4 == 0 && ($y % 100 != 0 || $y % 400 == 0);
    }
    sub _last_day_in_month {
        my ($y, $m) = @_;
        #die unless $m >= 1 && $m <= 12;
        return $m == 2
            ? ( _is_leap_year($y) ? 29 : 28 )
            : $days_in_month[$m];
    }
}

sub _normalize_date {
    my ($r) = @_;
    my ($y, $m, $d) = @$r{qw(year month day)};
    my $ymd = $r->{'date'} ||= _format_date($y, $m, $d);
    $r->{'day_of_week'} ||= $dow_cache{$ymd} ||= dayofweek($d, $m, $y) || 7;  # Sun --> 7, not 0
    if ($r->{'all_day'}) {
        $r->{'date_time'} = $r->{'date'};
    }
    else {
        my ($H, $M, $S) = @$r{qw(hour minute second)};
        $r->{'date_time'} = $r->{'date'} . _format_time($H, $M, $S);
    }
    return $r;
}

sub _parse_date {
    my ($dt) = @_;
    $dt =~ m{^(\d\d\d\d)[-/]?(\d\d)[-/]?(\d\d)} or die;
    return ($1, $2, $3);
}

sub _format_date {
    my ($y, $m, $d) = @_;
    return sprintf('%04d%02d%02d', $y, $m, $d);
}

sub _format_time {
    my ($H, $M, $S) = @_;
    return '' unless defined $H;
    return sprintf('T%02d%02d%02d', $H, $M || 0, $S || 0);
}

sub _day_after {
    my ($dt) = @_;
    my ($y, $m, $d) = _parse_date($dt);
    if ($d < 28 || $d != _last_day_in_month($y, $m)) {
        # YYYY-MM-DD --> YYYY-MM-(DD+1)
        $d++;
    }
    elsif ($m == 12) {
        # YYYY-12-31 --> (YYYY+1)-01-01
        $y++;
        $m = 1;
        $d = 1;
    }
    else {
        # YYYY-MM-nn --> YYYY-(MM+1)-01
        $m++;
        $d = 1;
    }
    return _format_date($y, $m, $d);
}

sub _day_before {
    my ($dt) = @_;
    my ($y, $m, $d) = _parse_date($dt);
    if ($d > 1) {
        $d--;
    }
    elsif ($m == 1) {
        $y--;
        $m = 12;
        $d = 31;
    }
    else {
        $d = _last_day_in_month($y, --$m);
    }
    return _format_date($y, $m, $d);
}

sub _iter_dates {
    my ($dt1, $dtn) = @_;
    return if $dt1 > $dtn;
    my ($y, $m, $d)    = _parse_date($dt1);
    my ($yn, $mn, $dn) = _parse_date($dtn);
    my $dlim = _last_day_in_month($y, $m);
    return sub {
        my $dt = _format_date($y, $m, $d++);
        return if $dt gt $dtn;
        if ($d > $dlim) {
            $d = 1;
            $m++;
            if ($m > 12) {
                $y++;
                $m = 1;
            }
            $dlim = _last_day_in_month($y, $m);
        }
        return $dt;
    }
}

1;

=pod

=head1 NAME

Remind::Parser - parse `remind -lp' output

=head1 SYNOPSIS

    use Remind::Parser;

    $parser = Remind::Parser->new(...);

    $parser->parse(\*STDIN);

    $reminders = $parser->reminders;
    foreach $rem (@$reminders) {
        ($Y, $M, $D) = @$rem{qw(year month day)};
        $descrip = $rem->{'description'};
    }

    $days = $parser->days;
    foreach $day (@$days) {
        $reminders_for_day = $day->{'reminders'};
        foreach $rem (@$reminders_for_day) {
            ...
        }
    }

=head1 DESCRIPTION

B<Remind::Parser> parses a stream produced by B<remind(1)> and intended for
back-end programs such as B<rem2ps(1)> or B<wyrd(1)>.

The input must have been produced by invoking B<remind -l -p[>I<num>B<]>;
for details on this format, see L<rem2ps(1)>.

=head1 PUBLIC METHODS

=over 4

=item B<new>(I<%args>)

    $parser = Remind::Parser->new;
    $parser = Remind::Parser->new('strict' => 1);

Create a new parser.  The following (key, value) pairs may be supplied; they
have the same effect as calling the mutator method with the same name; see
below.

=over 4

=item B<strict>

=item B<strip_times>

=item B<fill_gaps>

=back

=item B<strict>([I<boolean>])

    $is_strict = $parser->strict;
    $parser->strict(1);  # Be strict
    $parser->strict(0);  # Don't be strict

Get or set the parser's B<strict> property.  If B<strict> is set, the B<parse>
method will complain about invalid input, e.g., lines of input following the
C<# rem2ps end> line.

This option is off by default.

=item B<strip_times>([I<boolean>])

    $will_strip_times = $parser->strip_times;
    $parser->strip_times(1);  # Strip times
    $parser->strip_times(0);  # Don't strip times

Setting the B<strip_times> option will result in a reminder's time being
stripped from the beginning of the reminder.  It's much better to invoke remind
using B<-b2> instead if you don't want these times to appear, but this option
is available just in case you need it for some reason.

This option is off by default.

=item B<fill_gaps>([I<boolean>])

    $will_fill_gaps = $parser->fill_gaps;
    $parser->fill_gaps(1);  # Fill gaps
    $parser->fill_gaps(0);  # Don't fill gaps

If B<fill_gaps> is set, then when the B<days> method is called, any days that
have no reminders but that fall within the operative date range will be
represented in the value returned.

This may also be specified on a case-by-case basis when calling B<days>.

=item B<parse>(I<$filehandle>)

    $reminders = Remind::Parser->parse(\*STDIN);

Parse the contents of a filehandle, returning a reference to a list of
reminders.  The input must have been produced by invoking
B<remind -l -p[>I<num>B<]>; otherwise, it will not be parsed correctly.
(If remind's B<-pa> option was used, "pre-notification" reminders are correctly
parsed but cannot be distinguished from other reminders.)

Each reminder returned is a hash containing the following elements:

=over 4

=item B<description>

The reminder description (taken from the B<MSG> portion of the remind(1)
source).

=item B<date>

The reminder's date, in ISO8601 C<compact> format, e.g., C<20080320>.

=item B<date_time>

The reminder's date (and time, if it's a timed event), in ISO8601 C<compact>
format, e.g., C<20080320> or C<20080320T104500>.  Keep in mind that remind
doesn't assume any particular time zone.

=item B<year>

=item B<month>

=item B<day>

=item B<day_of_week>

The day, month, year, and day of week of the reminder.  Days of the week are
numbered 1 to 7 and start with Monday.

=item B<all_day>

If this element is present and has a true value, the reminder is an all-day
event.  Otherwise, it's a timed event.

=item B<hour>

=item B<minute>

The hour and minute of the reminder, if it's a timed reminder.  Absent
otherwise.

=item B<duration>

If the reminder has a duration, this is set to a reference to a hash with
B<hours>, B<minutes>, and B<seconds> elements with the appropriate values.
Otherwise, there is no B<duration> element.

=item B<tag>

The B<TAG> string from the remind(1) source.  Absent if no B<TAG> string was
present.

=item B<special>

The B<SPECIAL> string from the remind(1) source.  Absent if no B<SPECIAL> string
was present.

=item B<line>

=item B<file>

The line number and file name of the file containing the reminder.

=item B<event>

=item B<instance>

These two elements, both integers, together uniquely identify a reminder.
Multiple reminders that are all triggered from the same line in the same file
share the same B<event> identifier but have distinct B<instance> identifiers.

=back

=item B<reminders>

    $reminders = $parser->reminders;

This method returns a reference to the same array of reminders that was returned
by the B<parse> method.

=item B<days>

    $days = $parser->days;                    # Rely on $parser_fill_gaps
    $days = $parser->days('fill_gaps' => 1);  # Override $parser->fill_gaps
    $days = $parser->days('fill_gaps' => 0);  # Override $parser->fill_gaps

Returns a reference to an array of days for each of which one or more reminders
was triggered.  (If the B<fill_gaps> option is set, then days that have no
reminders but that fall within the operative date range will also be present.)

Each day is represented by a hash with the following elements:

=over 4

=item B<date>

The date in YYYYmmdd form.

=item B<year>

=item B<month>

=item B<day>

=item B<day_of_week>

The date expressed in all the same ways as it is in reminders.

=item B<reminders>

A reference to an array of reminders for the day.  Each reminder is a reference
to a hash whose members are as described above.  (In fact, each element in
B<reminders> is a reference to the same hash found in the return values of the
B<parse> and B<reminders> methods.)

=back

=back

=head1 BUGS

There are no known bugs.  Please report any bugs or feature requests via RT at
L<http://rt.cpan.org/NoAuth/Bugs.html?Queue=Remind-Parser>; bugs will be
automatically passed on to the author via e-mail.

=head1 TO DO

Offer an option to read the reminder's source?

Parse formats other than that produced by C<remind -l -p[a|num]>?

Add an option to skip reminders with unrecognized B<SPECIAL>s?

=head1 AUTHOR

Paul Hoffman (nkuitse AT cpan DOT org)

=head1 COPYRIGHT

Copyright 2007-2009 Paul M. Hoffman.

This is free software, and is made available under the same terms as Perl
itself.

=head1 SEE ALSO

L<remind(1)>,
L<rem2ps(1)>,
L<wyrd(1)>

=cut

# vim:fenc=utf-8:et:sw=4:ts=4:sts=4
