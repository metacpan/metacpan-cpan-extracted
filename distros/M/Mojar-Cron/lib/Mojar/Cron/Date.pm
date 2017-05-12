package Mojar::Cron::Date;
use Mojo::Base -strict;

our $VERSION = 0.011;

use Carp 'croak';
use POSIX 'strftime';

use overload
  '""' => sub { ${$_[0]} },
  '<=>' => sub { $$a cmp $$b },
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
  croak 'Bad date' unless $$self =~ /^(\d\d\d\d)-(\d\d)-(\d\d)\b/;
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
  $date //= ref $self ? $$self : croak 'Missing required date';
  $date =~ /^(\d{4})-(\d\d)-(\d\d)\b/ or croak "Bad date format ($date)";
  strftime($format // '%Y-%m-%d', 0, 0, 12, $3, $2 - 1, $1 - 1900);
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
  my $this = $self->dow;
  $self->roll(($dow - $this) % 7);
}

1;
__END__

=head1 NAME

Mojar::Cron::Date - Bare naked ISO dates

=head1 SYNOPSIS

  say Mojar::Cron::Date->$_ for qw(yesterday today tomorrow);

=head1 DESCRIPTION

Simple methods for manipulating simple dates.

=head1 CONSTRUCTORS

=head2 current

The date of the current UTC time.

=head2 today

The date of the current local time.

=head2 tomorrow

The date after today.

=head2 yesterday

The date before today.

=head1 METHODS

=head2 after

=head2 before

=head2 dow

=head2 format

=head2 is_weekend

=head2 next

=head2 previous

=head2 roll

=head2 roll_back

=head2 roll_to

=head2 yearweek

=head2 yearweekday

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2016, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
