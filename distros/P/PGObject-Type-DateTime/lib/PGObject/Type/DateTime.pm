package PGObject::Type::DateTime;

use 5.010;
use Carp;
use strict;
use warnings;
use base qw(DateTime);
use DateTime::TimeZone;
use PGObject;

=head1 NAME

PGObject::Type::DateTime - DateTime Wrappers for PGObject

=head1 VERSION

Version 2.0.2

=cut

our $VERSION = 2.000002;
our $default_tz = DateTime::TimeZone->new(name => 'UTC');


=head1 SYNOPSIS

   PGObject::Type::DateTime->register();

Now all Datetime, Timestamp, and TimestampTZ types are returned 
returned as datetime objects.  Date and time modules may require subclasses
to serialize properly to the database.

=head1 ONGOING WORK IN 2.X

During the 2.x series we expect to work on better NULL support.  Right now this
is all delegated to clild classes, but there are likely to be cases where we
add this to our library directly.

=head1 DESCRIPTION

This module provides a basic wrapper around DateTime to allow PGObject-framework
types to automatically tie date/time related objects, but we handle date and
timestamp formats in our from_db routines.

This specific module only supports the ISO YMD datestyle.  The MDY or DMY 
datestyles may be usable in future versions but datestyles other than ISO raise
ambiguity issues, sufficient that they cannot always even be used in PostgreSQL as input.

This module also provides basic default handling.  Times are assigned a date of
'0001-01-01' and dates are assigned a time of midnight.  Whether this is set is
persisted, along with whether timezones are set, and these are returned to a 
valid ISO YMD format on export, if a date component was initially set.

This means you can use this for general math without worrying about many of the
other nicities.  Parsing ISO YMD dates and standard times (24 hr format) is 
supported via the from_db interface, which also provides a useful way of handing
dates in.

=head1 SUBROUTINES/METHODS

=head2 register

By default registers 'date', 'time', 'timestamp', and 'timestamptz'

=cut

sub register {
    my $self = shift @_;
    croak "Can't pass reference to register \n".
          "Hint: use the class instead of the object" if ref $self;
    my %args = @_;
    my $registry = $args{registry};
    $registry ||= 'default';
    my $types = $args{types};
    $types = ['date', 'time', 'timestamp', 'timestamptz'] 
           unless defined $types and @$types;
    for my $type (@$types){
        if ($PGObject::VERSION =~ /^1\./) { # 1.x
            my $ret = 
                PGObject->register_type(registry => $registry, pg_type => $type,
                                  perl_class => $self);
        } else { # higher than 1.x
            require PGObject::Type::Registry;
            PGObject::Type::Registry->register_type(
                 registry => $registry, dbtype => $type, apptype => $self
            );
        }
    }
    return 1;
}

=head2 _new

Constructor for the PGDate object. Fully compliant with DateTime
C<_new> constructor which it uses internally to instantiate objects.

We need to hook this constructor instead of the regular C<new> one,
because this one is referred to directly on numerous occasions.

=cut

sub _new {
  my $class = shift;
  my (%args) = @_;
  my $self = $class->SUPER::_new(@_);
  bless $self, $class;
  $self->{_pgobject_is_date} = (defined $args{year} && $args{year} > 1) ? 1 : 0;
  $self->{_pgobject_is_time} = (defined $args{hour}) ? 1 : 0;
  $self->{_pgobject_is_tz}   = (defined $args{time_zone}) ? 1 : 0;
  return $self;
}

=head2 today

Wraps C<DateTime::today>, clearing the internal flag which
causes C<is_time()> to return a non-false value.

=cut

sub today {
    my $class = shift;
    my $self = $class->SUPER::today(@_);
    $self->{_pgobject_is_time} = 0;
    return $self;
}

=head2 last_day_of_month

Wraps C<DateTime::last_day_of_month>, clearing the internal flag which
causes C<is_time()> to return a non-false value.

=cut

sub last_day_of_month {
    my $class = shift;
    my $self = $class->SUPER::last_day_of_month(@_);
    $self->{_pgobject_is_time} = 0;
    return $self;
}

=head2 from_day_of_year

Wraps C<DateTime::from_day_of_year>, clearing the internal flag which
causes C<is_time()> to return a non-false value.

=cut

sub from_day_of_year {
    my $class = shift;
    my $self = $class->SUPER::from_day_of_year(@_);
    $self->{_pgobject_is_time} = 0;
    return $self;
}

=head2 truncate( to => ... )

Wraps C<DateTime::from_day_of_year>, clearing the internal flag which
causes C<is_time()> to return a non-false value, if the C<to> argument
is not one of C<second>, C<minute> or C<hour>.

=cut

sub truncate {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::truncate(@_);
    $self->{_pgobject_is_time} = 0
        if ! grep { $args{to} eq $_} qw/ hour minute second /;
    return $self;
}

=head2 from_db

Parses a date from YYYY-MM-DD format and generates the new object based on it.

=cut

sub from_db {
    my ($class, $value) = @_;
    my ($year, $month, $day, $hour, $min, $sec, $nanosec, $tz);
    $value = '' if not defined $value;
    $value =~ /(\d{4})-(\d{2})-(\d{2})/ 
          and ($year, $month, $day) = ($1, $2, $3);
    $value =~ /(\d+):(\d+):([0-9.]+)([+-]\d{1,4})?/ 
          and ($hour, $min, $sec, $tz) = ($1, $2, $3, $4);
    $tz ||= $default_tz; # defaults to UTC
    $tz .= '00' if $tz =~ /([+-]\d{2}$)/;
    ($sec, $nanosec) = split /\./, $sec if $sec;
    $nanosec *= 1000 if $nanosec;
    my $self = "$class"->new(
        year       => $year    || 1,
        month      => $month   || 1,
        day        => $day     || 1,
        hour       => $hour    || 0,
        minute     => $min     || 0,
        second     => $sec     || 0,
        nanosecond => $nanosec || 0,
        time_zone  => $tz      || 0,
        );
    $self->is_time(0) if ! defined $hour;
    $self->is_tz(0) if $tz == $default_tz;
    return $self;
}

=head2 to_db

Returns the date in YYYY-MM-DD format.

=cut

sub to_db {
    my ($self) = @_;
    return undef unless ($self->is_date or $self->is_time);
    my $dbst = '';
    my $offset = $self->offset;
    $offset = $offset / 60;
    my $offset_min = $offset%60;
    $offset = $offset / 60;
    my $sign = ($offset > 0)? '+' : '-';
    $offset = $sign . sprintf('%02d', abs($offset));

    if ($offset_min){
       $offset = "$offset$offset_min";
    }

    $dbst .= $self->ymd if $self->is_date;
    $dbst .= ' ' if $self->is_date and $self->is_time;
    $dbst .= $self->hms . '.' . $self->microsecond if $self->is_time;
    $dbst .= $offset if $self->time_zone ne $default_tz and $self->is_time;
    return $dbst;
}

=head2 is_date($to_set)

If $to_set is set, sets this.  In both cases, returns whether the object is now
a date.

=cut

sub is_date {
    my ($self, $val) = @_;
    if (defined $val){
       $self->{_pgobject_is_date} = $val;
    }
    return $self->{_pgobject_is_date};
}

=head2 is_time($to_set)

If $to_set is set, sets this.  In both cases, returns whether the object is now
a time.

=cut


sub is_time {
    my ($self, $val) = @_;
    if (defined $val){
       $self->{_pgobject_is_time} = $val;
    }
    return $self->{_pgobject_is_time};
}

=head2 is_tz($to_set)

If $to_set is set, sets this.  In both cases, returns whether the object is now
a date.

=cut

sub is_tz {
    my ($self, $val) = @_;
    if (defined $val){
       $self->{_pgobject_is_tz} = $val;
    }
    return $self->{_pgobject_is_tz};
}

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-type-datetime at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Type-DateTime>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Type::DateTime


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Type-DateTime>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Type-DateTime>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Type-DateTime>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Type-DateTime/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013-2017 The LedgerSMB Core Team

This program is released under the following license: BSD


=cut

1; # End of PGObject::Type::DateTime
