package Month::Simple;

use 5.010;
use strict;
use warnings;
use Date::Simple qw/ymd/;
use Time::Local qw/timelocal/;
use Carp qw/croak/;

use Data::Dumper;

our $VERSION = '0.04';

use overload
    q[""] => sub { my $d = shift->first_day; return substr "$d", 0, 7 },
    '+'   => sub { $_->[0]->delta($_[1])     },
    '-'   => sub { $_->[0]->delta(-$_[1])    },
    cmp   => sub { $_[0]->first_day cmp __PACKAGE__->new($_[1])->first_day  },
    ;

sub new {
    my ($class, $str) = @_;
    $class = ref($class) || $class;
    if (ref($str) && $str->isa('Date::Simple')) {
        return bless { day => ymd($str->year, $str->month, 1) }, $class;
    }
    elsif ($str && $str =~ /^(\d{4})-?(\d{2})(?:-\d\d)?$/) {
        return bless { day => ymd($1, $2, 1) }, $class;
    }
    elsif ($str && $str eq 'timestamp') {
        my ($mon, $year) = (localtime $_[2])[4, 5];
        return bless { day => ymd($year + 1900, $mon + 1, 1) }, $class;
    }
    elsif ($str) {
        croak "Invalid month '$str' (valid: YYYY-MM, YYYYMM, YYYY-MM-DD)";
    }
    else {
        my ($mon, $year) = (localtime $^T)[4, 5];
        return bless { day => ymd($year + 1900, $mon + 1, 1) }, $class;
    }
}

sub first_day {
    shift->{day};
}

sub last_day {
    shift->delta(1)->first_day - 1;
}

sub delta {
    my ($self, $delta) = @_;
    $delta = int $delta;
    return $self unless $delta;
    my $d = $self->first_day;
    while ($delta > 0) {
        # there's no way we can advance more than one month
        # when starting from the first of a month 
        $d += 31;
        $d = ymd($d->year, $d->month, 1);
    }
    continue {
        $delta--;
    }
    while ($delta < 0) {
        $d--;
        $d = ymd($d->year, $d->month, 1);
    }
    continue {
        $delta++
    }
    return $self->new($d);
}

sub first_second {
    my $self = shift;
    my $d = $self->first_day;
    return timelocal(0, 0, 0, 1, $d->month - 1, $d->year - 1900);
}

sub last_second {
    my $self = shift;
    $self->next->first_second - 1;
}

sub month { shift->{day}->month }
sub year  { shift->{day}->year }

sub prev { shift->delta(-1) };
sub next { shift->delta(1)  };

=head1 NAME

Month::Simple - Simple month-based date arithmetics

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Month::Simple;

    my $month = Month::Simple->new();
    my $prev  = $month->prev;
    my $stamp = $prev->first_second;
    my $in_yr = $month->delta(12);

=head1 METHODS

=head2 new

    Month::Simple->new();             # current month, using $^T as base
    Month::Simple->new('2011-01');
    Month::Simple->new('2011-01-02'); # day is ignored
    Month::Simple->new(timestamp => time); # extract month from UNIX timestamp

Creates a new C<Month::Simple> object. If no argument is provided, the current
month (based on the startup of the script, i.e. based on C<$^T>) is returned.

The argument can be a date in format C<YYYY-MM>, C<YYYYMM>, C<YYYY-MM-DD>
or a L<Date::Simple> object. Days are ignored.

=head2 prev

Returns a new C<Month::Simple> object for the month before the invocant month.

=head2 next

Returns a new C<Month::Simple> object for the month after the invocant month.

=head2 delta(N)

Returns a new C<Month::Simple> object. For positive C<N>, it goes forward C<N>
months, and backwards for negative C<N>.

=head2 first_second

Returns a UNIX timestamp for the first second of the month.

=head2 last_second

Returns a UNIX timestamp for the last second of the month.

=head2 month

Returns the month as an integer between 1 and 12.

    say Month::Simple->new(201602)->month;      2

=head2 year

Returns the year as an integer.

    say Month::Simple->new(201602)->year;       2016

=head2 first_day

Returns a L<Date::Simple> object for the first day of the month.

=head1 State of this module

This module has been in production usage for quite some time, and is
considered complete in the sense that no more features are planned.

=head1 AUTHOR

Moritz Lenz, C<< <moritz.lenz at noris.de> >> for the noris network AG.

=head1 BUGS

Please report any bugs or feature requests to C<bug-month-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Month-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Month::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Month-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Month-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Month-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Month-Simple/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Moritz Lenz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Month::Simple
