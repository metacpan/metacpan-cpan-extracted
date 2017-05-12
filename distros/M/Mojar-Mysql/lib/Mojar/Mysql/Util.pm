package Mojar::Mysql::Util;
use Mojo::Base -strict;

our $VERSION = 0.011;

require Carp;

sub import {
  my $caller = caller;
  my %want = map {$_ => 1} @_;

  no strict 'refs';
  *{"${caller}::find_monotonic_first"} = \&find_monotonic_first
    if $want{find_monotonic_first};

  # Need a closure for lookup => cannot use Exporter
  *{"${caller}::lookup"} = sub { lookup($caller, @_) } if $want{lookup};
}

our $FindRangeSize = 200;

sub find_monotonic_first {
  my ($dbh, $schema, $table, $column, $condition) = @_;
  Carp::croak $column .'Missing required condition' unless defined $condition;
  my $debug = $ENV{MOJAR_MYSQL_UTIL_DEBUG};

  my ($min, $max) = $dbh->selectrow_array(sprintf
q{SELECT MIN(%s), MAX(%s)
FROM %s.%s},
    $column, $column,
    $schema, $table
  );

  if (ref $condition eq 'CODE') {
    # Perl callback
    my $sth_row = $dbh->prepare(sprintf
q{SELECT *
FROM %s.%s
WHERE %s = ?},
      $schema, $table,
      $column
    );

    my $row;
    do {
      # Check minimum
      $row = $dbh->selectrow_hashref($sth_row, undef, $min);
      return $min if $condition->($row);

      # Check maximum
      $row = $dbh->selectrow_hashref($sth_row, undef, $max);
      return undef unless $condition->($row);  # Problem with data

      # Check range
      if ($max - $min <= $FindRangeSize) {
        my $candidate = $min;
        do {
          ($candidate) = $dbh->selectrow_array(sprintf(
q{SELECT MIN(%s)
FROM %s.%s
WHERE ? < %s},
              $column,
              $schema, $table,
              $column),
            undef,
            $candidate
          );
          $row = $dbh->selectrow_hashref($sth_row, undef, $candidate);
        } until $condition->($row);
        return $candidate;
      }

      # Calculate new
      # First find mean
      my $new = $min + int( ($max - $min) / 2 + 0.1 );
      # then find first record after that...
      my ($candidate) = $dbh->selectrow_array(sprintf(
q{SELECT MIN(%s)
FROM %s.%s
WHERE ? <= %s},
          $column,
          $schema, $table,
          $column),
        undef,
        $new
      );
      if ($candidate >= $max) {
        # ...or before that
        ($candidate) = $dbh->selectrow_array(sprintf(
q{SELECT MAX(%s)
FROM %s.%s
WHERE %s <= ?},
            $column,
            $schema, $table,
            $column),
          undef,
          $new
        );
        return undef if $candidate <= $min;  # Problem with data
      }
      $new = $candidate;
      # $min < $candidate < $max

      $row = $dbh->selectrow_hashref($sth_row, undef, $new);
      if ($condition->($row)) {
        $max = $new;
      }
      else {
        $min = $new;
      }
      warn $min, ' : ', $max if $debug;
    } while 1;
  }

  else {
    # SQL where-clause
    my $sth_row = $dbh->prepare(sprintf
q{SELECT COUNT(*)
FROM %s.%s
WHERE %s = ?
AND (%s)},
      $schema, $table,
      $column,
      $condition
    );
    my $sth_range = $dbh->prepare(sprintf
q{SELECT MIN(%s)
FROM %s.%s
WHERE ? <= %s
  AND %s <= ?
  AND (%s)},
      $column,
      $schema, $table,
      $column,
      $column,
      $condition
    );

    # Brute force (for demos)
#    return $dbh->selectrow_arrayref($sth_range, undef, $min, $max)->[0];

    my $satisfied;
    do {
      # Check range
      if ($max - $min <= $FindRangeSize) {
        my ($solution) = $dbh->selectrow_array($sth_range, undef, $min, $max);
        return $solution;
      }

      # Check minimum
      ($satisfied) = $dbh->selectrow_array($sth_row, undef, $min);
      return $min if $satisfied;

      # Check maximum
      ($satisfied) = $dbh->selectrow_array($sth_row, undef, $max);
      return undef unless $satisfied;  # Problem with data

      # Calculate new
      # First find mean
      my $new = $min + int( ($max - $min) / 2 + 0.1 );
      # then find first record after that...
      my ($candidate) = $dbh->selectrow_array(sprintf(
q{SELECT MIN(%s)
FROM %s.%s
WHERE ? <= %s},
          $column,
          $schema, $table,
          $column),
        undef,
        $new
      );
      if ($candidate >= $max) {
        # ...or before that
        ($candidate) = $dbh->selectrow_array(sprintf(
q{SELECT MAX(%s)
FROM %s.%s
WHERE %s <= ?},
            $column,
            $schema, $table,
            $column),
          undef,
          $new
        );
        return undef if $candidate <= $min;  # Problem with data
      }
      $new = $candidate;
      # $min < $candidate < $max

      ($satisfied) = $dbh->selectrow_array($sth_row, undef, $new);
      if ($satisfied) {
        $max = $new;
      }
      else {
        $min = $new;
      }
      warn $min, ' : ', $max if $debug;
    } while 1;
  }
}

sub lookup {
  my ($class, $name, $schema, $table, $key_col, $value_col) = @_;
  Carp::croak 'Wrong number of args' unless @_ == 6;
  Carp::croak qq{Lookup '$name' invalid} unless $name =~ /^[a-zA-Z_]\w*$/;

  my $code = <<EOT;
package $class;
sub $name {
  my \$dbh = shift;
  if (\@_ == 1) {
    return \$dbh->selectrow_arrayref(
q{SELECT $value_col
FROM ${schema}.$table
WHERE $key_col = ?},
      undef,
      \$_[0]
    )->[0];
  }
  \$dbh->do(
q{REPLACE INTO ${schema}.$table
SET $value_col = ?
WHERE $key_col = ?},
    undef,
    \$_[1], \$_[0]
  );
  return;
}
EOT
  warn "-- Lookup $name in $class\n$code\n\n" if $ENV{MOJAR_MYSQL_UTIL_DEBUG};
  Carp::croak "Mojar::Mysql::Util error: $@" unless eval "$code;1";
}

1;
__END__

=head1 NAME

Mojar::Mysql::Util - MySQL utility functions

=head1 SYNOPSIS

  use Mojar::Mysql::Util 'find_monotonic_first';

  my $key_val = find_monotonic_first(
    $dbh, 'Orders', 'CustomerOrder', 'iOrderId', q{'2010-01-01' <= dPlaced}
  );

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 find_monotonic_first

  $key_val = find_monotonic_first($dbh, $schema, $table, $field, $condition)

Finds the first value for the specified field for which the record satisfies
the condition.  The condition must be monotonic increasing with respect to the
field in question.  This means that as you go through records in order of
increasing values of the field, once the condition is satisfied, it is also
satisfied for all later records.  The condition is any string of SQL that is valid within the parentheses of

  SELECT ... WHERE (...);

The most common application for this is when the field is the primary key of
the table and the condition focuses on a field that is not indexed.  For
example, finding the first order placed within the past 28 days; the order id
is the primary key and the datetime is not indexed.  Another scenario is having
a batch job attribute analytics events to orders; to find where to resume, it
needs to find the first record having NULL for its events field.
Non-scientific trials suggest on tables of 20+ million records, using
find_monotonic_first is around 50 times faster than letting MySQL do a linear
search.

Bear in mind that results are unreliable if the condition is non-monotonic.  A
special case is when the final record is found not to satisfy the condition;
the algorithm concludes that the condition is insatiable and bails out (with
undef).  For tables with fewer than 2 million records, there is probably little
point to using this.  It makes most sense with InnoDB or XtraDB tables when you
want to find the first primary key value that satisfies a condition that can't
be found using indices.  In this case the algorithm is searching the clustered
(primary) index in a way that has maximum immunity to record locking.  So it's
not just fast, it avoids contention with concurrent threads.

=head1 SEE ALSO

L<Mojar::Util>, L<Mojo::Util>.
