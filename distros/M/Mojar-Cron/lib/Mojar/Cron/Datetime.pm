package Mojar::Cron::Datetime;
use Mojo::Base -strict;

our $VERSION = 0.101;

use Carp qw(carp croak);
use Mojar::ClassShare 'have';
use Mojar::Cron::Util qw(balance life_to_zero normalise_local normalise_utc
    time_to_zero zero_to_time utc_to_ts local_to_ts);
use POSIX 'strftime';

our @TimeFields = qw(sec min hour day month year);

# Normal maxima (soft limits)
%Mojar::Cron::Datetime::Max = (
  sec  => 59,
  min  => 59,
  hour => 23,
  day => 30,
  month  => 11,
  weekday => 6
);
@Mojar::Cron::Datetime::Max =
    @Mojar::Cron::Datetime::Max{qw(sec min hour day month weekday)};

# Class attributes
# (not usable on objects)

# Constructors

sub new {
  my $class = shift;
  my $self;
  if (ref $class) {
    # Clone
    $self = [ @$class ];
    $class = ref $class;
    carp sprintf 'Useless arguments to new (%s)', join ',', @_ if @_;
  }
  elsif (@_ == 0) {
    # Zero member
    $self = [0,0,0, 0,0,0];
  }
  elsif (@_ == 1) {
    # Pre-generated
    croak "Non-ref argument to new ($self)" unless ref($self = shift);
  }
  else {
    $self = [ @_ ];
  }
  bless $self => $class;
  return $self->normalise;  # Calculate weekday etc
}

sub from_string {
  my ($class, $iso_date) = @_;
  $class = ref $class || $class;
  if ($iso_date
      =~ /^(\d{4})-(\d{2})-(\d{2})(?:T|\s)(\d{2}):(\d{2}):(\d{2})Z?$/) {
    return $class->new(life_to_zero($6, $5, $4, $3, $2, $1));
  }
  croak "Failed to parse datetime string ($iso_date)";
}

sub from_timestamp {
  my ($class, $timestamp, $is_local) = @_;
  $class = ref $class || $class;
  my @parts = $is_local ? localtime $timestamp
                        : gmtime $timestamp;
  return $class->new( time_to_zero @parts );
}

sub now { shift->from_timestamp(time, @_) }

# Public methods

sub copy {
  my ($self, $original) = @_;
  return unless ref $original;
  return $self->clone(@_) unless ref $self;
  @$self = @$original;
  return $self;
}

sub reset_parts {
  my ($self, $end) = @_;
  $$self[$_] = 0 for 0 .. $end;
  return $self;
}

sub weekday {
  my $self = shift;
  return +($self->normalise(@$self))[6];
}

sub normalise {
  my $self = shift;
  my @parts = @_ ? @_ : @$self;
  @parts = time_to_zero normalise_utc zero_to_time @parts;
  return @parts if @_;  # operating on argument

  @$self = @parts;  # operating on invocant
  return $self;
}

sub to_timestamp {
  my ($self, $is_local) = @_;
  return $is_local ? local_to_ts zero_to_time @$self
                   : utc_to_ts zero_to_time @$self;
}

sub to_string {
  my $self = shift;
  $self = shift if @_ and ref $_[0];
  return strftime pop || '%Y-%m-%d %H:%M:%S', zero_to_time @$self;
}

1;
__END__

=head1 NAME

Mojar::Cron::Datetime - Lightweight datetime with small footprint

=head1 SYNOPSIS

  use Mojar::Cron::Datetime;
  say Mojar::Cron::Datetime->now->to_string;
  my $d = Mojar::Cron::Datetime->from_string('2001-12-25 00:00:01');
  $d->day($d->day + 14);
  $d->normalise;
  say "$d";

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 C<new>

Construct a datetime from passed arguments.

  $d = Mojar::Cron::Datetime->new;  # zero datetime
  $d = $datetime->new;  # clone
  $d = Mojar::Cron::Datetime->new([00, 00, 20, 26, 06, 112]);
  $d = Mojar::Cron::Datetime->new(00, 00, 20, 26, 06, 112);

The first constructs the zero datetime '1900-01-01 00:00:00'.  The second clones
the value of C<$datetime>.  The third uses the passed value (2012-07-27 21:00:00
London time expressed in UTC).  The fourth does the same but using its own
reference.

=head2 C<now>

  $d = Mojar::Cron::Datetime->now;
  $d = Mojar::Cron::Datetime->now($use_local);
  $d = $d->now;

Constructs a datetime for now.  Uses UTC clock unless passed a true value
(indicating to use local clock).  If called as an object method, ignores the
value of the object, so it gives the same result as the class method.  (Compare
to C<new> which uses the object's value.)

=head2 C<from_string>

  $d = Mojar::Cron::Datetime->from_string('2012-07-27 20:00:00');
  $d = Mojar::Cron::Datetime->from_string('2012-07-28T01:00:00', 1);

Constructs a datetime by parsing an ISO 8601 string.  (The method only supports
the formats shown, where 'T' is optional, and not any of the other 8601
variants.)  Uses UTC clock unless passed a true value (indicating to use local
clock).  Both examples result in the same value if the machine's clock is in
UTC+5.

=head1 METHODS

=head2 C<copy>

  $second = Mojar::Cron::Datetime->new->copy($first);

Copies the constituent values from another datetime object.

=head2 C<normalise>

=head2 C<to_string>

  say "$dt";
  say $dt->to_string;
  say $dt->to_string('%Y-%m-%d %H:%M:%S');
  say Mojar::Cron::Datetime->to_string($dt, '%Y-%m-%d');
  say Mojar::Cron::Datetime->to_string([00,00,00, 25,11,101], '%A');

Stringifies the datetime object using the given format.  The default format is
'%Y-%m-%d %H:%M:%S'.  The first three examples are equivalent.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012--2016, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<DateTime>, L<Time::Moment>.
