package Mojar::Cron::Timestamp;
use Mojo::Base -base;

our $VERSION = 0.011;

use Carp 'carp';
use POSIX qw( mktime strftime );
use Time::Local 'timegm';

# Class attributes

has format => '%Y-%m-%d %H:%M:%S';
has is_local => 0;

# Constructors

sub new {
  my $class = shift;
  my $ts = 0;
  if (ref $class) {
    # Clone
    $ts = $$class;
    $class = ref $class;
    carp "Useless arguments to new (@{[ join ',', @_ ]})" if @_;
  }
  elsif (@_ >= 1) {
    # Pre-generated
    $ts = ref $_[0] ? ${ shift() } : shift;
  }
  return bless \$ts => $class;
}

sub now { my $class = shift; $class = ref $class || $class; $class->new(time) }

sub from_string {
  my ($class, $iso_date, $local) = @_;
  my $sec = 0;
  if ($iso_date =~ /^(\d{4})-(\d{2})-(\d{2})(?:T|\s)(\d{2}):(\d{2}):(\d{2})Z?$/) {
    $sec = ($local || $class->{is_local})
        ? mktime($6, $5, $4, $3, $2 - 1, $1 - 1900)
        : timegm($6, $5, $4, $3, $2 - 1, $1 - 1900);
  }
  return $class->new($sec);
}

# Public methods

sub to_string {
  my ($class, $self, $local) = (undef, shift, undef);
  if (ref $self) {
    # object method
    $class = ref $self;
    $local = shift;
  }
  else {
    # class method
    $class = $self;
    $self = shift;
    $self = \$self unless ref $self;
    $local = shift;
  }
  return ($local || $class->is_local)
      ? strftime $class->format, localtime $$self
      : strftime $class->format, gmtime $$self;
}

1;
__END__

=head1 NAME

Mojar::Cron::Timestamp - Timestamp as an object

=head1 DESCRIPTION

This was experimental and I do not see it having a future.  I thought it would
help elucidate the Cron algorithm but in the end I stopped using this and used
instead

  Datetime->from_timestamp(...);
  Datetime->to_timestamp(...);
