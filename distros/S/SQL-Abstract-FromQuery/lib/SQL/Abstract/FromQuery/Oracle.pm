package SQL::Abstract::FromQuery::Oracle;

use strict;
use warnings;
use parent 'SQL::Abstract::FromQuery';


sub date {
  my ($self, $h) = @_;

  my $date_format = $self->{date_format} || 'YYYY-MM-DD';
  my $date = $self->next::method($h);

  return \ ["to_date(?, '$date_format')", $date];
}


sub time {
  my ($self, $h) = @_;

  my $time_format = $self->{time_format} || 'HH24:MI:SS';
  my $time = $self->next::method($h);

  return \ ["to_date(?, '$time_format')", $time];
}


1; # End of SQL::Abstract::FromQuery::Oracle

__END__


=head1 NAME

SQL::Abstract::FromQuery::Oracle - SQL::Abstract::FromQuery extension for Oracle queries


=head1 SYNOPSIS

  my $parser = SQL::Abstract::FromQuery->new(
    -components => [qw/Oracle/],
  );

=head1 DESCRIPTION

This subclass automatically adds Oracle C<TO_DATE(...)> conversions
in SQL generated from date and time fields.


=head1 AUTHOR

Laurent Dami, C<< <laurent.dami AT justice.ge.ch> >>

=cut


