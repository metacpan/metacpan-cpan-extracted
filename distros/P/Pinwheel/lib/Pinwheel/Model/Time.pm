package Pinwheel::Model::Time;

use strict;
use warnings;

use POSIX qw();
use Time::Local qw(timegm_nocheck timelocal_nocheck);

use Pinwheel::Model::DateBase;
use Pinwheel::Model::Date;

our @ISA = qw(Pinwheel::Model::DateBase);


# Constructors

sub new
{
    my ($class, $s, $utc) = @_;
    $s = CORE::time() unless defined($s);
    my $t = $utc ? [gmtime $s] : [localtime $s];
    return bless({ s => $s, t => $t, u => $utc ? 1 : 0 }, $class);
}

sub now { new Pinwheel::Model::Time(CORE::time(), shift) }
sub utc { new Pinwheel::Model::Time(timegm_nocheck(_make_t(@_)), 1) }
sub local { new Pinwheel::Model::Time(timelocal_nocheck(_make_t(@_)), 0) }
sub now_0seconds
{
    my $t = now(@_);
    $t->{s} -= $t->{t}[0];
    $t->{t}[0] = 0;
    return $t;
}

sub _make_t
{
    ($_[5] || 0, $_[4] || 0, $_[3] || 0, $_[2] || 1, ($_[1] || 1) - 1, $_[0]);
}

sub _pair
{
    $_[0]->{pair} = $_[1];
    return $_[0];
}

sub _derived
{
    my ($self, $y, $m, $d, $hh, $mm, $ss) = @_;
    my $fn = $self->{u} ? \&timegm_nocheck : \&timelocal_nocheck;
    return new Pinwheel::Model::Time(&$fn($ss, $mm, $hh, $d, $m, $y), $self->{u});
}


# Date/time values

sub timestamp { $_[0]->{s} }
sub hour { $_[0]->{t}[2] }
sub min { $_[0]->{t}[1] }
sub sec { $_[0]->{t}[0] }


# Formatting

sub hh_mm
{
    my $t = $_[0]->{t};
    return sprintf('%02d:%02d', $t->[2], $t->[1]);
}

sub hh_mm_ss
{
    my $t = $_[0]->{t};
    return sprintf('%02d:%02d:%02d', $t->[2], $t->[1], $t->[0]);
}

sub rfc822
{
    my $utc = $_[0]->getutc;
    my $t = $utc->{t};
    return sprintf('%s, %02d %s %d %02d:%02d:%02d GMT',
        $utc->short_day_name,
        $t->[3], $utc->short_month_name, $t->[5] + 1900,
        $t->[2], $t->[1], $t->[0]
    );
}

sub iso8601
{
    my $t = $_[0]->{t};
    my $s = sprintf(
        '%d-%02d-%02dT%02d:%02d:%02d',
        $t->[5] + 1900, $t->[4] + 1, $t->[3], $t->[2], $t->[1], $t->[0]
    );
    return $s . ($t->[8] ? '+01:00' : 'Z');
}

sub iso8601_ical
{
    my $t = $_[0]->{t};
    my $s = sprintf(
        '%d%02d%02dT%02d%02d%02d',
        $t->[5] + 1900, $t->[4] + 1, $t->[3], $t->[2], $t->[1], $t->[0]
    );
    $s .= 'Z' unless $t->[8];
    return $s;
}


# Date/time adjustment

sub getutc
{
    my $self = shift;
    return $self if $self->{u};
    return $self->{pair} if ($self->{pair});
    return $self->{pair} = Pinwheel::Model::Time->new($self->{s}, 1)->_pair($self);
}

sub getlocal
{
    my $self = shift;
    return $self unless $self->{u};
    return $self->{pair} if ($self->{pair});
    return $self->{pair} = Pinwheel::Model::Time->new($self->{s}, 0)->_pair($self);
}

sub add
{
    my ($self, $seconds) = @_;
    return new Pinwheel::Model::Time($self->{s} + $seconds, $self->{u});
}


# Type conversion

sub toJson
{
    return $_[0]->timestamp;
}

sub sql_param
{
    return $_[0]->getutc->strftime('%Y-%m-%d %H:%M:%S');
}

sub route_param
{
    return $_[0]->timestamp;
}

sub to_date
{
    Pinwheel::Model::Date::date($_[0]->{t}[5] + 1900, $_[0]->{t}[4] + 1, $_[0]->{t}[3]);
}


1;

__DATA__

=head1 NAME 

Pinwheel::Model::Time - represents a date with a time-of-day part (1 second
granularity), either in UTC or local time zone

=head1 SYNOPSIS

    # Constructors:

    $t = Pinwheel::Model::Time->new($epoch_secs[, $utc]);
    $t = Pinwheel::Model::Time::now([$utc]);
    $t = Pinwheel::Model::Time::utc($y, $m, $d, $H, $M, $S);
    $t = Pinwheel::Model::Time::local($y, $m, $d, $H, $M, $S);

    $t = Pinwheel::Model::Time::now_0seconds([$utc]);
    # same as 'now' but with the 'seconds' field zeroed

    $t2 = $t->getutc;     # $t but in UTC
    $t2 = $t->getlocal;   # $t but in local time zone
    $t2 = $t->add($secs); # add $secs seconds to $t; preserve UTC/Local

    # Accessors:

    $t->timestamp;        # seconds since UNIX epoch
    $t->hour;             # 0..23
    $t->min;              # 0..59
    $t->sec;              # 0..59

    # Formatters:

    $t->hh_mm;            # "00:00".."23:59"
    $t->hh_mm_ss;         # "00:00:00".."23:59:59"
    $t->rfc822;           # e.g. "Mon, 01 Sep 2008 12:34:56 GMT" (always GMT)
    $t->iso8601;          # e.g. "2008-09-01T12:34:56Z" or "2008-09-01T12:34:56+01:00"
    $t->iso8601_ical;     # e.g. "20080901T123456Z" or "20080901T123456"

    $t->toJson;           # ?
    $t->sql_param;        # Database formatting, e.g. "2008-05-31 06:30:00" (always UTC)
    $t->route_param;      # ?

    # Conversion:

    $d = $t->to_date;     # Convert to Pinwheel::Model::Date

    # See Pinwheel::Model::DateBase for additional methods

=head1 SEE ALSO

L<Pinwheel::Model::DateBase>, L<Pinwheel::Model::Date>.

=head1 BUGS

Assumes that the only non-UTC time zone is +01:00.

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut
