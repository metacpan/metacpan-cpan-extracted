package SQL::Abstract::FromQuery::Oracle;

use strict;
use warnings;
use parent 'SQL::Abstract::FromQuery';
use UNIVERSAL::DOES  qw/does/;

our $time_fmt         = q{HH24:MI:SS};
our $datetime_fmt_ISO = qq{YYYY-MM-DD"T"$time_fmt};

#======================================================================
# override actions hooked to the grammar
#======================================================================

sub date {
  my ($self, $h) = @_;

  my $date = $self->next::method($h); # returns date in ISO format YYYY-MM-DD

  # datetime format is OK for a date without time, Oracle accepts it
  return \ ["TO_DATE(?, '$datetime_fmt_ISO')", $date];
}


sub time {
  my ($self, $h) = @_;

  my $time = $self->next::method($h); # returns time in ISO format HH:MM:SS
  return \ ["TO_DATE(?, '$time_fmt')", $time];
}


sub datetime {
  my ($self, $h) = @_;

  # hack : we remove the "TO_DATE()" parts before calling the parent method ...
  # and then re-inject the "TO_DATE()" on the global result

  $_ = @{$$_}[1] for @{$h}{qw/date time/}; # just keep the bind values

  my $datetime = $self->next::method($h); # returns dt as YYYY-MM-DDTHH:MM:SS

  return \ ["TO_DATE(?, '$datetime_fmt_ISO')", $datetime];
}



#======================================================================
# override finalization callback
#======================================================================


sub finalize {
  my ($self, $result) = @_;

  # if to_date(..) was used without any comparison operator, we must add
  # an '=' because SQL::Abstract won't do it automatically for values
  # of shape \[..] (i.e. literal SQL with placeholders and bind values)
  foreach my $val (values %$result) {
    if (does($val, 'REF') && does($$val, 'ARRAY')) {
      $$val->[0] =~ s/^TO_DATE/= TO_DATE/;
    }
  }

  return $self->next::method($result);
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


