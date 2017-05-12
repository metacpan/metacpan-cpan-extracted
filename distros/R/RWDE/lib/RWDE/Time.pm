package RWDE::Time;

use strict;
use warnings;

use RWDE::DB::Record;
use RWDE::DB::DefaultDB;

use base qw(RWDE::DB::DefaultDB RWDE::DB::Record);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 516 $ =~ /(\d+)/;

=pod

=head1 RWDE::Time

Class for performing time related queries. RWDE doesn't use any external perl libraries, instead
it queries the database set up in the project configuration file.

=cut


=head2 fetch_time({ timestamp, interval })

Fetch a calculated date. Provided a timestamp and the desired interval the database will be queried
and the resulting calculation returned back. An added bonus is that the standard sql for dates can be
used here when passing your parameters.

For example, to return the timestamp representing 5 days for right now:

RWDE::Time->fetch_time({ timestamp => 'now()', interval => "5 days"});

=cut

sub fetch_time {
  my ($self, $params) = @_;

  my @required = qw( timestamp interval );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  #insert regex for timestamp validation and interval validation...

  my $select = 'CAST(? as timestamp) + CAST(? as interval)';
  my @query_params = ($$params{timestamp}, $$params{interval});

  return $self->fetch_single({ select => $select, query_params => \@query_params });
}

=head2 fetch_difference({ start_stamp, stop_stamp })

Fetch the number of days elapsed between two dates. Provided a start and stop date return the number of full days 
that have passed between the two. An added bonus is that the standard sql for dates can be used here when passing 
your parameters.

Note the parameters can be formatted as timestamps but the method will cast them to dates anyway. If you are 
looking for the total elapsed time between two timestamps use fetch_exact_difference.

For example, to return how many days have passed since New Years 2008:

RWDE::Time->fetch_diff({ start_stamp => '01/01/2008 00:00:00', stop_stamp => 'now()' });

=cut

sub fetch_diff {
  my ($self, $params) = @_;

  if (not defined $$params{start_stamp} or not defined $$params{stop_stamp}) {
    return;
  }

  my $select = 'CAST(? as date) - CAST(? as date)';

  my @query_params = ($$params{stop_stamp}, $$params{start_stamp});

  return $self->fetch_single({ select => $select, query_params => \@query_params });
}

=head2 is_before({ start_stamp, stop_stamp })

Returns true if start_stamp is before stop_stamp, false otherwise

=cut

sub is_before{
  my ($self, $params) = @_;

  RWDE::RObject->check_params({ required => ['start_stamp','stop_stamp'], supplied => $params });

  #insert regex for timestamp validation and interval validation...

  my $select = "to_char(CAST(? as timestamp) - CAST(? as timestamp),'SS')";

  my @query_params = ($$params{stop_stamp}, $$params{start_stamp});

  my $diff =  $self->fetch_single({ select => $select, query_params => \@query_params });

  if ($diff > 0) {
    return 1;
  }
  else{
    return 0;
  }
}

=head2 now()

Fetch the timestamp that currently represents exactly "now".

This is useful for timestamping events within the system, etc.

RWDE::Time->now() would returns a timestamp that conforms to your database default timestamp representation

=cut

sub now {
  my ($self, $params) = @_;

  return $self->fetch_time({ timestamp => 'NOW()', interval => 0 });
}

=head2 days_passed

This is a macro to fetch_diff whereby the ending timestamp is always represented by the current date.

This simply returns back the number of days that have passed between the start stamp and the time when
the method is executed.

=cut

sub days_passed {
  my ($self, $params) = @_;

  my $interval = RWDE::Time->fetch_diff({ start_stamp => $$params{timestamp}, stop_stamp => 'now()' });

  # extract the number from the db response with the optional minus
  #$interval =~ m/([-]?\d+)\s+(day)/;

  #my $days = $1;
  #unless (defined($days)) {
  #  $days = 0;
  #}

  return $interval;
}

=head2 format_date

Generate a time hash that represents the timestamp parameter.

The method parses through the timestamp and separates each of the timestamp components into a separate key.
date, time, year, month, and day are all represented within the time hash

=cut

sub format_date {
  my ($self, $params) = @_;

  my @required = qw( timestamp );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  my @parts = split / /, $$params{timestamp};

  my $time = {};
  $$time{date} = $parts[0];
  $$time{time} = $parts[1];

  @parts = split(/-/, $$time{date});

  $$time{year}  = $parts[0];
  $$time{month} = $parts[1];
  $$time{day}   = $parts[2];

  return $time;
}

=head2 format_qdate

Generate a qdate from the passed in timestamp parameter.

=cut

sub format_qdate {
  my ($self, $params) = @_;

  my @required = qw( timestamp );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  my $time = $self->format_date({ timestamp => $$params{timestamp} });

  return ("$$time{month}/$$time{day}/$$time{year}");
}

=head2 format_rfc

Generate an RFC 822 formatted date from the passed in timestamp parameter.

RSS requires this specific RFC date formatting

=cut

sub format_rfc {
  my ($self, $params) = @_;

  my @required = qw( timestamp );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  my $select = 'to_char(?::TIMESTAMP WITH TIME ZONE, ?)';
  my @query_params = ($$params{timestamp}, 'Dy, DD Mon YYYY HH12:MI:SS TZ');

  return $self->fetch_single({ select => $select, query_params => \@query_params });
}

=head2 format_human

Generate an arbitrary human readable date from the passed in timestamp parameter.

The returned date formating is: YYYY-MM-DD HH12:MI:SS TZ

=cut

sub format_human {
  my ($self, $params) = @_;

  my @required = qw( timestamp );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  my $select = 'to_char(?::TIMESTAMP WITH TIME ZONE, ?)';
  my @query_params = ($$params{timestamp}, 'YYYY-MM-DD HH12:MI:SS TZ');

  return $self->fetch_single({ select => $select, query_params => \@query_params });
}

=head2 extract_dow

Determine the day of week of a given timestamp parameter

=cut

sub extract_dow {
  my ($self, $params) = @_;
  my @required = qw( timestamp );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  my $select       = 'EXTRACT(DOW FROM ?::timestamp)';
  my @query_params = ($$params{timestamp});

  return $self->fetch_single({ select => $select, query_params => \@query_params });
}

=head2 db_format_timestamp

Take a database timestamp and make it look nice for humans to read. 

This is for Postgres database which tack on a numeric timezone.

=cut

sub db_format_timestamp {
  my ($self, $db_timestamp) = @_;

  return substr $db_timestamp, 0, 19;
}

1;
