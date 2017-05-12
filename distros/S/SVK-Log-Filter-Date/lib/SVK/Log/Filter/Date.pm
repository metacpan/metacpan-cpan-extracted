package SVK::Log::Filter::Date;

use strict;
use warnings;

use base qw( SVK::Log::Filter::Selection );
use Date::PeriodParser qw( parse_period );
use Time::Local        qw( timegm       );

our $VERSION = '0.0.1';

sub setup {
    my ($self) = @_;

    my $period = $self->{argument} || q{};
    my ( $from, $to ) = parse_period($period);

    # validate the date range
    die "Can't parse the period '$period' : $to\n"
        if $from == -1;

    # store the date ranges for later
    $self->{from} = $from;
    $self->{to}   = $to;

    return;
}

sub revision {
    my ($self, $args) = @_;

    # we need a commit date  (Is there ever not a svn:date property?)
    my $date = $args->{props}->{'svn:date'};
    $self->pipeline('next') if !$date;

    # can we parse the date
    my $commit_time = $self->date_to_epoch($date)
        or $self->pipeline('next');

    # skip revisions that are too late
    $self->pipeline('next') if $commit_time > $self->{to};

    # stop the pipeline entirely if a revision is too early
    $self->pipeline('last') if $commit_time < $self->{from};

    return;
}

sub date_to_epoch {
    my ($self, $svn_date) = @_;

    # parse the date
    my ($y, $M, $d, $h, $m, $s) = split(/[-T:.Z]/, $svn_date)
        or return;

    # normalize the date parts to match what timegm() expects
    $y -= 1900;
    $M--;
    return timegm( $s, $m, $h, $d, $M, $y );
}

1;

__END__

=head1 NAME

SVK::Log::Filter::Date - selects revisions based on svn:date property

=head1 SYNOPSIS

    > svk log --filter 'date today' //mirror/project/trunk
    ----------------------------------------------------------------------
    r1234 (orig r456):  author | 2006-10-10 14:58:23 -0600

    More changes to Foo.pm after lunch.
    ----------------------------------------------------------------------
    r1233 (orig r455):  author | 2006-10-10 09:28:52 -0600

    I made some changes to Foo.pm this morning.
    ----------------------------------------------------------------------

=head1 DESCRIPTION

An SVK log filter which selects for revisions with an svn:date property within
a particular date range.  Conceptually, this is similar to using
C<-r {DATE}:{DATE}>, but the date range is specified by a natural language phrase
and the time is localtime instead of UTC. Any phrase that
L<Date::PeriodParser> understands can be used to specify a date range.

Examples:

    > svk log --filter 'date today'
    # show all commits from today
    
    > svk log --filter 'date yesterday'
    # show all commits from yesterday

    > svk log --filter 'date two days ago'
    # show commits that happened during a day two days ago

See the documentation for L<Date::PeriodParser> supported phrases.

=head1 STASH/PROPERTY MODIFICATIONS

Date does not modify the stash or revision properties.

=head1 BUGS

None known.

=head1 AUTHORS

Michael Hendricks <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
The MIT License

Copyright (c) 2006 Michael Hendricks (<michael@ndrix.org>).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
