package Pinwheel::Model::Date;

use strict;
use warnings;

use POSIX qw();
use Time::Local qw(timegm_nocheck);

use Pinwheel::Model::DateBase;
use Pinwheel::Model::Time;

our @ISA = qw(Pinwheel::Model::DateBase);


# Constructors

sub new
{
    my ($class, $s) = @_;
    my @t = gmtime($s);
    $s += (12 - $t[2]) * 3600;
    $t[2] = 12;
    return bless({ s => $s, t => \@t }, $class);
}

sub now
{
    my $utc = shift;
    return Pinwheel::Model::Date->new(timegm_nocheck($utc ? gmtime : localtime));
}

sub parse
{
    my ($str) = @_;
    my ($y, $m, $d) = ($str =~ /^(\d{4})(?:-(\d{2}))?(?:-(\d{2}))?$/);
    return undef unless (defined $y);
    return Pinwheel::Model::Date::date($y, $m, $d);
}

sub date
{
    my ($y, $m, $d) = @_;
    return new Pinwheel::Model::Date(
        timegm_nocheck(0, 0, 12, $d || 1, ($m || 1) - 1, $y)
    );
}

sub from_bbc_week
{
    my ($y, $w) = @_;
    my ($date, $adjustment);
    
    $date = new Pinwheel::Model::Date(timegm_nocheck(0, 0, 12, 4, 0, $y));
    $adjustment = -(($date->wday + 1) % 7);
    return $date->offset(days => $adjustment + (7 * ($w - 1)));
}

sub from_iso_week
{
    my ($y, $w) = @_;
    my ($date, $adjustment);

    $date = new Pinwheel::Model::Date(timegm_nocheck(0, 0, 12, 4, 0, $y));
    $adjustment = -(($date->wday - 1) % 7);
    return $date->offset(days => $adjustment + (7 * ($w - 1)));
}

sub _derived
{
    my ($self, $y, $m, $d) = @_;
    return new Pinwheel::Model::Date(timegm_nocheck(0, 0, 12, $d, $m, $y));
}


# Formatting

sub iso8601
{
    my $t = $_[0]->{t};
    return sprintf('%d-%02d-%02d', $t->[5] + 1900, $t->[4] + 1, $t->[3]);
}


# Type conversion

sub toJson
{
    return $_[0]->{'s'};
}

sub sql_param
{
    my $t = $_[0]->{t};
    return sprintf('%d-%02d-%02d', $t->[5] + 1900, $t->[4] + 1, $t->[3]);
}

sub route_param
{
    return {
        year => $_[0]->{t}[5] + 1900,
        month => $_[0]->{t}[4] + 1,
        day => $_[0]->{t}[3]
    };
}

sub to_time
{
    Pinwheel::Model::Time::local($_[0]->{t}[5] + 1900, $_[0]->{t}[4] + 1, $_[0]->{t}[3]);
}

sub difference
{
    my ($self, $other) = @_;
    my $d = $self->{'s'} - $other->{'s'};
    return int(($d + ($d < 0 ? -43200 : 43200)) / 86400);
}

1;

__DATA__

=head1 NAME 

Pinwheel::Model::Date - represents a date (without a time-of-day part and without a time zone)

=head1 SYNOPSIS

    # Constructors:

    $d = Pinwheel::Model::Date->new($epoch_secs);

    $d = Pinwheel::Model::Date::now([$utc]);
        # if $utc is true: the current UTC date
        # otherwise (default): the current local date

    $d = Pinwheel::Model::Date::parse($str); 
        # $str can be like '2008' or '2008-05' or '2008-05-31'
        # missing parts default to "01"

    $d = Pinwheel::Model::Date::date($y[, $m[, $d]]);
        # missing parts default to 1 (Jan, 1st)

    $d = from_bbc_week($y, $w);
    $d = from_iso_week($y, $w);

    # Formatters:

    $d->iso8601;            # ISO8601 formatting, e.g. "2008-05-31"
    $d->toJson;             # ?
    $d->sql_param;          # Database formatting, e.g. "2008-05-31"
    $d->route_param;        # a hash ref, e.g. +{ year => 2000, month => 5, day => 31 }

    # Conversion:

    $t = $d->to_time;       # Convert to Pinwheel::Model::Time (using midnight local time)
    
    # Date calculations
    $d1->difference($d2);   # Returns the difference between two dates (in days)

    # See Pinwheel::Model::DateBase for additional methods

=head1 SEE ALSO

L<Pinwheel::Model::DateBase>, L<Pinwheel::Model::Time>.

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut
