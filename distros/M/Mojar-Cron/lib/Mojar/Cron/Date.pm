package Mojar::Cron::Date;
use Mojo::Base -strict;

our $VERSION = 0.021;

use Carp qw(croak);
use POSIX qw(strftime);
use Scalar::Util qw(blessed);

use overload
  '""'  => sub { ${$_[0]} },
  '<=>' => sub { (${$_[0]} cmp $_[1]) * ($_[2] ? -1 : 1) },
  fallback => 1;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $payload = @_ ? shift : ref $proto ? $$proto : $class->today;
  bless \$payload => $class;
}

sub today {
  my ($d, $m , $y) = (localtime)[3, 4, 5];
  return shift->new(sprintf '%04u-%02u-%02u', $y + 1900, $m + 1, $d);
}

sub current {
  my ($d, $m , $y) = (gmtime)[3, 4, 5];
  return shift->new(sprintf '%04u-%02u-%02u', $y + 1900, $m + 1, $d);
}

sub roll {
  my ($self, $days) = @_;
  croak 'Not a class method' unless ref $self;
  croak "Bad date format ($$self)" unless $$self =~ /^(\d{4})-(\d\d)-(\d\d)\b/a;
  $$self = strftime '%Y-%m-%d', 0, 0, 12, $3 + ($days // 0), $2 - 1, $1 - 1900;
  return $self;
}

sub roll_back { shift->roll(-(shift // 0)) }

sub after { shift->new->roll(shift) }

sub before { shift->new->roll(-(shift // 0)) }

sub next { shift->new->roll(1) }

sub previous { shift->new->roll(-1) }

sub tomorrow { shift->today->roll(1) }

sub yesterday { shift->today->roll(-1) }

sub format {
  my ($self, $format, $date) = @_;
  $date ||= ref $self ? $$self : croak 'Missing required date';
  croak "Bad date format ($date)" unless $date =~ /^(\d{4})-(\d\d)-(\d\d)\b/a;
  die "Unsupported platform ($^O)" unless $^O eq 'linux';
  strftime($format || '%Y-%m-%d', 0, 0, 0, $3, $2 - 1, $1 - 1900);
}

sub dow { shift->format('%u', @_) }

sub yearweek { shift->format('%G%V', @_) }

sub yearweekday { shift->format('%GW%V%u', @_) }

sub is_weekend {
  my $self = shift;
  my $dow = $self->dow(shift);
  $dow == 6 or $dow == 7;
}

sub roll_to {
  my ($self, $dow) = @_;
  croak 'Missing required day-of-the-week' unless defined $dow;
  my $day = $self->dow;
  $self->roll(($dow - $day) % 7);
}

sub epoch_days {
  my ($self) = @_;
  croak "Bad date format ($$self)" unless $$self =~ /^(\d{4})-(\d\d)-(\d\d)\b/a;
  die "Unsupported platform ($^O)" unless $^O eq 'linux';
  return _epoch_days($1, $2, $3);
}

sub sleeps {
  my ($self, $other) = @_;
  (blessed $other and $other->isa('Mojar::Cron::Date'))
    ? $other->epoch_days - $self->epoch_days
    : ref $other
      ? croak sprintf('Invalid type (%s)', ref $other)
      : $other - $self->epoch_days;
}

# Determine base value for epoch
my $Epoch = 0;  # starting point, affects base value
$Epoch = _epoch_days(1970, 1, 1);  # set base value
my %Cache = ();  # reset cache after above calculation

sub _epoch_days {
  # Args: ($year, $1-based-month, $day-of-month)
  # Borrowed from Time::Local...
  # Only expected to be correct on linux
  $_[2] + ($Cache{pack ss => @_[0, 1]} ||= do {
    my $month = ($_[1] + 9) % 12;
    my $year  = $_[0] - int($month / 10);

    365 * $year
    + int($year / 4) - int($year / 100) + int($year / 400)
    + int(($month * 306 + 5) / 10)
    - $Epoch;
  })
}

1;
__END__

=head1 NAME

Mojar::Cron::Date - Integer arithmetic for ISO dates

=head1 SYNOPSIS

  say Mojar::Cron::Date->$_ for qw(yesterday today tomorrow);

=head1 DESCRIPTION

Methods for manipulating simple dates.

First, make a date.  That should either be using your machine's local timezone:

  $local_date = Mojar::Cron::Date->yesterday;
  $local_date = Mojar::Cron::Date->today;
  $local_date = Mojar::Cron::Date->tomorrow;

or using UTC:

  $utc_date = Mojar::Cron::Date->current->previous;
  $utc_date = Mojar::Cron::Date->current;
  $utc_date = Mojar::Cron::Date->current->next;

or via a literal value:

  $date = Mojar::Cron::Date->new('2005-02-14');

or by copying:

  $copied_date = $date->new;

Then once you have a date, it is timezone-neutral -- you simply roll forwards or
backwards.

  $date->roll(1);
  $date->roll_back(1);
  $date->roll_back(7);
  $date->roll(-7);
  $date->roll_to(0);

Or you can go non-mutating by creating fresh dates equal to those values.

  $future_date = $date->next;
  $past_date = $date->previous;
  $past_date = $date->before(7);
  $past_date = $date->after(-7);
  $soon_date = $date->new->roll_to(0);

=head1 PORTABILITY CAVEAT

This module makes heavy use of C<POSIX::strftime> and is not expected to work on
platforms where that is missing or faulty.  It is tested regularly on linux.

=head1 CONSTRUCTORS

=head2 current

The date of the current UTC time.

  $utc_date = Mojar::Cron::Date->current;

=head2 today

The date of the current local time.

  $local_date = Mojar::Cron::Date->today;

=head2 tomorrow

The date after today.

  $local_date = Mojar::Cron::Date->tomorrow;

=head2 yesterday

The date before today.

  $local_date = Mojar::Cron::Date->yesterday;

=head1 METHODS

=head2 after

A non-mutating generator for a fresh date that is this many nights after the
source (invoker) date.

  $future_date = $date->after(28);

=head2 before

A non-mutating generator for a fresh date that is this many nights before the
source (invoker) date.

  $past_date = $date->before(28);

=head2 dow

The numeric weekday of this date.

  $date->roll_to(1);  # Now on a Monday
  my $dow_id = $date->dow;  # 1 : Mon

The answer will a number from 0 to 6, with 0 indicating Sunday and 6 Saturday.

=head2 format

  $epoch_seconds = $date->format('%s')
  $month_name = $date->format('%B')

Format the date to a string.

=head2 is_weekend

=head2 next

=head2 previous

=head2 roll

Roll date forwards by a number of nights.

  $date->roll(1);  # next day
  $date->roll(7);  # week later

=head2 roll_back

Roll date backwards by a number of nights.

  $date->roll_back(1);  # previous day
  $date->roll_back(7);  # week earlier

which are equivalent to

  $date->roll(-1);
  $date->roll(-7);

=head2 roll_to

Roll date forwards by the least amount to make it the specified weekday.  The
most it can roll forwards is 6 nights.

  $date->roll_to(0);  # 0 : Sun
  $date->roll_to(1);  # 1 : Mon
  ...
  $date->roll_to(6);  # 6 : Sat

If C<$date> is a Monday, then C<$date->roll_to(1)> will make no change since it
is already on a Monday.  On the other hand, C<$date->roll_to(0)> will make it
roll forwards 6 nights to get to the following Sunday.

Like the other C<roll*> methods, C<roll_to> is also a mutator.  For the non-mutating equivalent, first copy with C<new>.

  $soon = $date->new->roll_to(0);

=head2 sleeps (*linux only*)

How many sleeps till the specified date?  The answer will be positive if given a
future date, negative if given a past date.

  $sleeps = $date->sleeps($my_next_birthday);

=head1 FUNCTIONS

=head2 sort

  @sorted  = sort {$a cmp $b} @dates
  @reverse = sort {$b cmp $a} @dates
  @sorted  = sort {$a <=> $b} @dates
  @reverse = sort {$b <=> $a} @dates

Built-in forward and reverse sorting works, giving the same result with either
operator.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2016--2022, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
