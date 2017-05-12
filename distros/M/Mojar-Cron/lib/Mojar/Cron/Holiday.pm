package Mojar::Cron::Holiday;
use Mojo::Base -base;

use Carp 'croak';
use Mojar::Cron::Datetime;

# Attributes

has holidays => sub { {} };
has 'linked';
has 'error';

# Methods

sub holiday {
  my ($self, $date) = (shift, shift);
  $date //= substr(Mojar::Cron::Datetime->now->to_string, 0, 10);
  my $holidays = $self->holidays;
  my $linked = $self->linked;

  if (ref $date eq 'ARRAY') {
    # Recurse over a setter bundle
    return [map $self->holiday($_ => $_[0]), @$date] if @_;

    # Recurse over a getter bundle
    return [map $self->holiday($_), @$date];
  }

  # Scalar
  croak 'Bad format' unless $date =~ /^\d\d\d\d-\d\d-\d\d$/;

  # Setter
  $holidays->{$date} = !! $_[0], return $self if @_;

  # Getter
  return $holidays->{$date} if exists $holidays->{$date};

  # Defer if possible
  return $linked->holiday($date) if $linked;

  # Negative
  return undef;
}

sub next_holiday {
  my ($self, $date) = @_;
  $date //= substr(Mojar::Cron::Datetime->now->to_string, 0, 10);
  my $holidays = $self->holidays;

  my @dates = sort grep $holidays->{$_}, keys %$holidays;
  shift @dates while @dates and $dates[0] lt $date;
  @dates ? $dates[0] : undef;
}

sub load { croak q{Method 'load' not implemented by subclass} }

1;
__END__

=head1 NAME

Mojar::Cron::Holiday - Cache for the holidays

=head1 SYNOPSIS

  my $national = Mojar::Cron::Holiday->new(holidays => {
    '2014-12-24' => 1,
    '2014-12-25' => 1,
    '2015-01-01' => 1,
  });
  say 'Yippee!' if $national->holiday('2014-12-25');

  my $regional = Mojar::Cron::Holiday->new(holidays => {
    '2014-12-25' => 0,  # We work Christmas Day
    '2014-12-26' => 1   # but get Boxing Day in lieu
  });
  $regional->linked($national);  # regional is an overlay on national
  say 'Booo!' unless $regional->holiday('2014-12-25');
  say 'Phew!'
    if $regional->holiday('2014-12-24') and $regional->holiday('2014-12-26');

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 holidays

  $calendar->holidays({'2016-01-01' => 1});

A hashref holding the underlying holiday list.  A false value against a date
indicates it is not a holiday; useful when overriding a linked calendar.

It is equally convenient to set the holiday list using the holidays attribute
(with a hashref) or the holiday method (with an arrayref); choose whichever you
find more readable within your code.

=head2 linked

  $regional->linked($national);
  say 'National holiday' if $regional->linked->holiday('2016-01-04');

The linked attribute may hold another holiday object, to which queries are
passed whenever the current object has no opinion.  Thus a tree of holiday nodes
can be built.  The root of the tree might be national public holidays; below
that might be corporate holidays for the boss's birthday and when the warehouse
shuts for stocktaking; and below that might be a node for the annual leave of
each employee.  Commonly the tree is simpler: a node for project 'down' days,
linking to a node for public holidays.

=head1 METHODS

=head2 holiday

  $calendar->holiday('2016-01-04' => 1);
  $calendar->holiday(['2016-03-25', '2016-03-28'] => 0);
  say 'Bye!' if $calendar->holiday;
  say 'Discard the milk' if $calendar->holiday($yesterday);

A getter and setter for whether this calendar flags the date(s) as holiday.  The
date can be either a scalar (string) or an arrayref of such scalars.  If no date
is given, the current date is used.

When used as a setter, the second argument is a boolean.  For base or standalone
calendars, only positive results need be assigned; negatives are assigned when
you want to override a possible linked result.

=head2 next_holiday

  $anticipated = $calendar->next_holiday('2016-02-01');

Returns the next holiday on or following the given date.  If no date is given,
the current date is used.

=head1 RATIONALE

I need a small web service so that various apps can forecast when staff will be
in better moods.  The prime example is a gantt editor, which relies on holiday
information for forecasting when there is a glimmer of hope of work being done.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2014, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
