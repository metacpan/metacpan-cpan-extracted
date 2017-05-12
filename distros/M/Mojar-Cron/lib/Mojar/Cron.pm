package Mojar::Cron;
use Mojo::Base -base;

our $VERSION = 0.401;

use Carp 'croak';
use Mojar::Cron::Datetime;
use POSIX qw(mktime strftime setlocale LC_TIME);

# Fields of a cron pattern
our @Fields = qw(sec min hour day month weekday);

# Soft limits for defining ranges
my %Max; @Max{@Fields} = (59, 59, 23, 30, 11, 6);

# Array indices of a datetime record
use constant {
  SEC     => 0,
  MIN     => 1,
  HOUR    => 2,
  DAY     => 3,
  MONTH   => 4,
  YEAR    => 5,
  WEEKDAY => 6
};
# NB the distinction (YEAR) between this and @Fields

# Canonical names
my (%Month, %Weekday);
{
  my $old_locale = setlocale(LC_TIME);
  setlocale(LC_TIME, 'C');

  %Month   = map +(lc(strftime '%b', 0,0,0,1,$_,70) => $_), 0 .. 11;
  %Weekday = map +(lc(strftime '%a', 0,0,0,$_,5,70) => $_), 0 .. 6;

  setlocale(LC_TIME, $old_locale);
}

# Attributes

# Object has these seven attributes
has \@Fields;
has 'is_local';

# Public methods

sub new {
  my ($class, %param) = @_;

  # Exclude is_local from expansion
  my $is_local = delete $param{is_local};

  # Identify time pattern attributes
  my @values;
  if (exists $param{pattern}) {
    @values = split /\s+/, delete $param{pattern};
  }
  elsif (exists $param{parts}) {
    @values = @{ delete $param{parts} };
  }
  else {
    my $given_sec = exists $param{sec} ? 1 : undef;
    @values = map $param{$_}, @Fields;
    $values[0] = 0 unless $given_sec;  # Do not expand sec more than requested
    delete @param{@Fields};
  }
  # Apply default 'sec'
  unshift @values, '0' if @values < 6;  # Vivify sec

  croak(sprintf 'Unrecognised parameter (%s)', join ',', keys %param) if %param;
  %param = ();

  # Expand parameter values
  $param{$Fields[$_]} = expand($Fields[$_] => $values[$_]) for 0 .. 5;
  
  return $class->SUPER::new(%param, is_local => $is_local);
}

sub expand {
  # Function; not method
  my ($field, $spec) = @_;

  return undef if not defined $spec or $spec eq '*';

  my @vals;
  for my $val (split /,/, $spec) {
    my $step = 1;
    my $end;

    $val =~ s|/(\d+)$|| and $step = $1;

    $val =~ /^(.+)-(.+)$/ and ($val, $end) = ($1, $2);

    if ($val eq '*') {
      ($val, $end) = (0, $Max{$field});
    }
    elsif ($field eq 'day') {
      # Externally 1-31; internally 0-30
      defined and /^\d+$/ and --$_ for $val, $end;
    }
    elsif ($field eq 'month') {
      # Externally 1-12; internally 0-11
      defined and /^\d+$/ and --$_ for $val, $end;
      # Convert symbolics
      defined and exists $Month{lc $_} and $_ = $Month{lc $_} for $val, $end;
    }
    elsif ($field eq 'weekday') {
      # Convert symbolics
      defined and exists $Weekday{lc $_} and $_ = $Weekday{lc $_}
        for $val, $end;
      $end = 7 if defined $end and $end == 0 and $val > 0;
    }

    push @vals, $val;
    push @vals, $val while defined $end and ($val += $step) <= $end;

    if ($field eq 'weekday' and $vals[-1] == 7) {
      unshift @vals, 0 unless $vals[0] == 0;
      pop @vals;
    }
  }
  return [ sort {$a <=> $b} @vals ];
}

sub next {
  my ($self, $previous) = @_;
  # Increment to the next possible time and convert to datetime
  my $dt = Mojar::Cron::Datetime->from_timestamp(
      $previous + 1, $self->is_local);

  {
    redo unless $self->satisfiable(MONTH, $dt);

    if (defined $self->{day} and defined $self->{weekday}) {
      # Both day and weekday are defined, so the cron entry should trigger as
      # soon as _either_ of them is satisfied.  Therefore need to determine
      # which is satisfied sooner.

      my $weekday_dt = $dt->new;
      my $weekday_restart = not $self->satisfiable(WEEKDAY, $weekday_dt);
      my $next_by_weekday = $weekday_dt->to_timestamp($self->is_local);

      my $day_dt = $dt->new;
      my $day_restart = not $self->satisfiable(DAY, $day_dt);
      my $next_by_day = $day_dt->to_timestamp($self->is_local);

      if ($next_by_day <= $next_by_weekday) {
        $dt->copy($day_dt);
        redo if $day_restart;
      }
      else {
        $dt->copy($weekday_dt);
        redo if $weekday_restart;
      }
    }
    elsif (defined $self->{day}) {
      redo unless $self->satisfiable(DAY, $dt);
    }
    elsif (defined $self->{weekday}) {
      redo unless $self->satisfiable(WEEKDAY, $dt);
    }

    redo unless $self->satisfiable(HOUR, $dt);
    redo unless $self->satisfiable(MIN, $dt);
    redo unless $self->satisfiable(SEC, $dt);
  }

  return $dt->to_timestamp($self->is_local);
}

sub satisfiable {
  my ($self, $component, $dt) = @_;

  # The given $component of $self is a sequence of numeric slots.  Test whether
  # those slots can satisfy the corresponding component of $dt.  Shortcircuit
  # 'true' if slot is a wildcard.
  my $field = ($component == WEEKDAY) ? 'weekday' : $Fields[$component];
  my $slots = $self->{$field} // return 1;

  # $old : existing value; $new : same or next value satisfying cron
  my $old = ($component == WEEKDAY) ? $dt->weekday : $dt->[$component];
  my $new;
  # Grab first slot at least big enough
  for (@$slots) { $new = $_, last if $_ >= $old }

  # Can't manipulate WEEKDAY directly since it is tied to DAY.  Instead
  # manipulate DAY until goal is achieved.
  if ($component == WEEKDAY) {
    $component = DAY;
    $new = $dt->[DAY] + $new - $old if defined $new;  # adjust by the same delta
    $old = $dt->[DAY];

    if (not defined $new) {
      # Rollover (into following week)
      $dt->reset_parts(DAY - 1);
      # Add more days till we hit next occurrance of $slots->[0]
      # We know $dt->weekday is greater than all @$slots, so the following will
      # add less than a week to $dt->[DAY].
      $dt->[DAY] += $slots->[0] + 7 - $dt->weekday;

      $dt->normalise;
      return undef;
    }
    elsif ($new > $old) {
      # Component has moved up a slot
      $dt->reset_parts($component - 1);
    }
  }
  elsif (not defined $new) {
    # Rollover
    $dt->reset_parts($component - 1);
    $dt->[$component] = $slots->[0];
    $dt->[$component + 1]++;

    $dt->normalise;
    return undef;
  }
  elsif ($new > $old) {
    # Component has moved up a slot
    $dt->reset_parts($component - 1);
  }

  $dt->[$component] = $new;

  # Detect rollover of month and reset to next month
  my $was_month = $dt->[MONTH];
  $dt->normalise;

  if ($component == DAY and $was_month != $dt->[MONTH]) {
    $dt->reset_parts(DAY);
    return undef;
  }

  return 1;
}

1;
__END__

=head1 NAME

Mojar::Cron - Cron-style datetime patterns and algorithm

=head1 SYNOPSIS

  use Mojar::Cron;
  my $c = Mojar::Cron->new(is_local => 1, pattern => '0 9 * * mon');
  my $t = time;
  $t = $c->next($t);  # next instance of 9am Monday
  say "Need to wait another $t seconds."

=head1 DESCRIPTION

A time pattern is a sequence of six components: second, minute, hour, day,
month, weekday (the component for 'second' may be omitted for brevity and
consistency with standard cron syntax) and supports C<@>-expressions in the
weekday component.  Each of the first four components consists of a
comma-separated list of patterns.

  2
  1,3,5
  1-4,6
  */2

The 'month' component can use those patterns, but may also use English prefices
in place of numbers.

  apr-jun,oct-dec  # instead of 4-6,10-12

The 'weekday' component can do similarly.

  mon-fri  # instead of 1-5
  mon,wed,fri  # instead of 1,3,5

(Note that this implementation also supports 'wrap around' patterns such as
C<fri-mon> and C<oct-mar>.)

In keeping with standard cron, a time pattern may specify sequences for both day
and weekday in the same pattern.  This can cause confusion because the pattern
is satisfied if either sequence is satisfied.

  00 00 00 01  * mon  # midnight on the first of each month and also each Monday

The weekday component may use C<@>-expressions, but in this case the 'day' and
'month' components must be unspecified.

  00 00 00  *  * @mon#1      # first Monday of each month
  00 00 16  *  * @5#L        # last Friday of each month
  00 00 16  *  * @week#L     # last week day (Mon-Fri) of each month
  00 00 03  *  * @weekend#1  # first weekend day (Sat-Sun) of each month

There are also special expressions which can replace the whole time pattern.

  00 01 00  *  * *  # @nightly
  00 01 06  *  * *  # @morningly
  00 01 12  *  * *  # @daily
  00 01 18  *  * *  # @eveningly

Cron patterns of the kind C<*/n> have a weakness that they only specify jumps
within their sequence.  For example the 'day' pattern C<*/15> will trigger on
1st, 16th, 31st January and then again on 1st February; the pattern resets at
the end of its sequence (month days).  This might not be what you expect or
want, so we also have yearday patterns.  These have the same behaviour, but
because they don't reset till the end of the year, they get closer to what
people expect.

  00 00 00  *  * :*/2  # every two days through the year

=head1 METHODS

=head2 C<new>

=head2 C<next>

=head2 C<expand>

=head2 C<satisfiable>

=head1 TROUBLESHOOTING

For consistency with cron, patterns are one-based for day and month, but
internally (using Mojar::Cron::Datetime) everything is zero-based.  So
when debugging your code C<[0,0,0,0,0,0]> would be '1900-01-01 00:00:00' and
C<[[0],[0],[0],undef,undef,[1]]> would be '00 00 00 * * 1'.

=head1 COPYRIGHT AND LICENCE

The main algorithm is thanks to Paul Evans (leonerd@leonerd.org.uk).  I hope I
have implemented it in a readable way, and it turns out doing so revealed
several bugs in the original.

Copyright (C) 2012, Paul Evans.

Copyright (C) 2012--2016, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Algorithm::Cron> (Paul has merged in bugfixes I sent.)
