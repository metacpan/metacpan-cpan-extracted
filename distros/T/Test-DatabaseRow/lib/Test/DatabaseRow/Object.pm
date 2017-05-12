package Test::DatabaseRow::Object;

# require at least a version of Perl that is merely ancient, but not
# prehistoric
use 5.006;

use strict;
use warnings;

our $VERSION = "2.01";

use Scalar::Util qw(blessed);
use Carp qw(croak);
our @CARP_NOT = qw(Test::DatabaseRow::Object);

use Test::DatabaseRow::Result;
use Test::Builder;

# okay, try loading Regexp::Common

# if we couldn't load Regexp::Common then we use the one regex that I
# copied and pasted from there that we need.  We could *always* do
# this, but at least this way if there's a bug in this regex they can
# upgrade Regexp::Common when it changes and they don't have to wait
# for me to upgrade this module too

our %RE;
unless (eval { require Regexp::Common; Regexp::Common->import; 1 }) {
  ## no critic (ProhibitComplexRegexes)
  $RE{num}{real} = qr/
    (?:(?i)(?:[+-]?)(?:(?=[0123456789]|[.])
    (?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)
    (?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))
  /x;
}

########################################################################
# constructor and accessors
#
# note that this is all written in the Moose style, even though we
# don't actually use Moose (because it's too big a dependency
# for this widely used Test module.)  Hopefully if you use Moose
# a lot (and you should) then the conventions used in this code will
# be understandable.
#
# The design pattern we use here is the "pull through accessor" meaning
# that a large amount of the work is done by 'read only' lazy accessors
# the first time they are read and then subsequently cached for future
# reads.  As the lazy accessors in turn request other lazy accessors
# simply requesting an accessor from a method may have a chain effect
# and do the majority of calculation that would traditionally be done
# within the method.
#
# Some of this code could have been made shorter via meta programing
# e.g. programming to dynamically create methods, making the has_XXX
# attributes automatic.  I've deliberately not done that since that
# would drastically reduce the readability of this code.  I'm not against
# that kind of thing, but it should be packaged up in it's own module,
# and that would end up re-inventing Moose...
#
########################################################################

## constructor #########################################################

# emulate moose somewhat by calling a _coerce_and_verify_XXX method
# if one exists
sub new {
  my $class = shift;
  my $self = bless {}, $class;
  while (@_) {
    my $key = shift;
    my $value = shift;
    my $method = $self->can("_coerce_and_verify_$key");
    $self->{ $key } = $method ? $method->($self,$value) : $value;
  }
  return $self;
}

## database related accessors ##########################################

# has dbh => ( is => 'ro' );
sub dbh     { my $self = shift; return $self->{dbh} }
sub has_dbh { my $self = shift; return exists $self->{dbh} }

# has table => ( is => 'ro', predicate => 'has_table' );
sub table     { my $self = shift; return $self->{table} }
sub has_table { my $self = shift; return exists $self->{table} }

# has where => ( is => 'ro', isa => 'HashRef[HashRef]'. coerce => 1, predicate => "has_where");
sub where     { my $self = shift; return $self->{where} }
sub has_where { my $self = shift; return exists $self->{where} }
sub _coerce_and_verify_where {
  my $self = shift;
  my $where = shift;

  # coerce it all to equals tests if we were using the
  # shorthand array notation
  if (ref $where eq "ARRAY") {
    $where = { "=" => { @{ $where } } };
  }

  # check we've got a hash of hashes
  unless (ref($where) eq "HASH")
    { croak "Can't understand the argument passed in 'where'" }
  foreach my $valuehash (values %{ $where }) {
    unless (ref($valuehash) eq "HASH")
      { croak "Can't understand the argument passed in 'where'" }
  }

  return $where;
}

# has sql_and_bind => ( is => 'ro', predicate => "has_sql_and_bind", lazy_build => 1 );
sub sql_and_bind {
  my $self = shift;
  return $self->{sql_and_bind} ||= $self->_build_sql_and_bind;
}
sub has_sql_and_bind { my $self = shift; return exists $self->{sql_and_bind} }
sub _coerce_and_verify_sql_and_bind {
  my $self = shift;
  my $sql_and_bind = shift;

  return $sql_and_bind if ref $sql_and_bind eq "ARRAY";
  return [$sql_and_bind] if ref $sql_and_bind eq "" || blessed($sql_and_bind);
  croak "Can't understand the sql";
}
sub _build_sql_and_bind {
  my $self = shift;

  unless ($self->has_table)
    { croak "Needed to build SQL but no 'table' defined" }
  unless ($self->has_where)
    { croak "Needed to build SQL but no 'where' defined" }

  my @conditions;
  my $where = $self->where;
  foreach my $oper (sort keys %{$where}) {
    my $valuehash = $where->{ $oper };

    foreach my $field (sort keys %{$valuehash}) {
      # get the value
      my $value = $valuehash->{ $field };

      # should this be "IS NULL" rather than "= ''"?
      if ($oper eq "=" && !defined($value)) {
        push @conditions, "$field IS NULL";
        next;
      }

      # just an undef?  I hope $oper is "IS" or "IS NOT"
      if (!defined($value)) {
        push @conditions, "$field $oper NULL";
        next;
      }

      # proper value, quote it properly
      # we do this instead of adding to bind because it makes the
      # error messages much more readable
      unless ($self->has_dbh)
        { croak "Needed to quote SQL during SQL building but no 'dbh' defined" }
      push @conditions, "$field $oper ".$self->dbh->quote($value);
    }
  }

  return ["SELECT * FROM @{[ $self->table ]} WHERE @{[ join ' AND ', @conditions ]}"];
}

# has force_utf8 => ( is => "ro" )
sub force_utf8     { my $self = shift; return $self->{force_utf8} }
sub has_force_utf8 { my $self = shift; return exists $self->{force_utf8} }

# has db_results => ( is => "ro", lazy_build => 1 );
sub db_results {
  my $self = shift;
  return $self->{db_results} ||= $self->_build_db_results;
}
sub has_db_results { my $self = shift; return exists $self->{db_results} }
sub _build_db_results {
  my $self = shift;

  unless ($self->dbh)
    { croak "Needed fetch results but no 'dbh' defined" }

  # make all database problems fatal
  local $self->dbh->{RaiseError} = 1;

  # load "Encode" if we need to do utf8 munging
  if ($self->force_utf8) {
    eval { require Encode; 1 }
      or croak "Can't load Encode, but force_utf8 is enabled";
  }

  # get the SQL and execute it
  my ($sql, @bind) = @{ $self->sql_and_bind };
  my $sth = $self->dbh->prepare($sql);
  $sth->execute( @bind );

  # store the results
  my @db_results;
  while (my $row_data = $sth->fetchrow_hashref) {

    # munge the utf8 flag if we need to
    if ($self->force_utf8)
      { Encode::_utf8_on($_) foreach values %{ $row_data } }

    # store the data
    push @db_results, $row_data;
  }

  return \@db_results;
}

# has db_results_dumped => ( is => "ro", lazy_build => 1 );
sub db_results_dumped {
  my $self = shift;
  return $self->{db_results_dumped} ||= $self->_build_db_results_dumped;
}
sub has_db_results_dumped { my $self = shift; return exists $self->{db_results_dumped} }
sub _build_db_results_dumped {
  my $self = shift;

  # get the results iff some was already fetched, otherwise we don't have any
  my $results = $self->has_db_results ? $self->db_results : [];

  my $builder = Test::Builder->new;
  if ($builder->can("explain")) {
    my ($str) = $builder->explain($results);
    return $str;
  }

  croak "Cannot dump db results since the version of Test::Builder installed does not support 'explain'";
}

## test related accessors ##############################################


# has "test" => ( is => "ro", isa => "Bool", predicate => "has_check_all_rows")
sub check_all_rows {
  my $self = shift;
  return $self->{check_all_rows}
}

# has "test" => ( is => "ro", predicate => "has_tests", isa =>"tests", coerce => 1 )
sub tests     { my $self = shift; return $self->{tests} }
sub has_tests { my $self = shift; return exists $self->{tests} }
sub _coerce_and_verify_tests {
  my $self = shift;
  my $tests = shift;

  # if this is a an array, coerce it into a hash
  if (ref $tests eq "ARRAY") {
    my @tests = @{ $tests };

    if (@tests % 2 != 0)
      { croak "Can't understand the passed test arguments" }

    # for each key/value pair
    $tests = {};
    while (@tests) {
      my $key   = shift @tests;
      my $value = shift @tests;

      # set the comparator based on the type of value we're comparing
      # against.  This can lead to some annoying cases, but if they
      # want proper comparison they can use the non dwim mode

      if (!defined($value)) {
        $tests->{'eq'}{ $key } = $value;
        next;
      }

      if (ref($value) eq "Regexp") {
        $tests->{'=~'}{ $key } = $value;
        next;
      }

      if ($value =~ /\A $RE{num}{real} \z/x) {
        $tests->{'=='}{ $key } = $value;
        next;
      }

      # default to string comparison
      $tests->{'eq'}{ $key } = $value;
    }
  }

  # check we've got a hash of hashes
  unless (ref($tests) eq "HASH")
    { croak "Can't understand the argument passed in 'tests': not a hashref or arrayref" }
  foreach my $valuekey (keys %{ $tests }) {
    unless (ref($tests->{ $valuekey }) eq "HASH")
      { croak "Can't understand the argument passed in 'tests': key '$valuekey' didn't contain a hashref" }
  }

  return $tests;
}

# has results => ( is => "ro", predicate => "has_results")
sub results     { my $self = shift; return $self->{results} }
sub has_results { my $self = shift; return exists $self->{results} }

# has max_results => ( is => "ro", predicate => "has_max_results")
sub max_results     { my $self = shift; return $self->{max_results} }
sub has_max_results { my $self = shift; return exists $self->{max_results} }

# has min_results => ( is => "ro", predicate => "has_rmin_esults")
sub min_results     { my $self = shift; return $self->{min_results} }
sub has_min_results { my $self = shift; return exists $self->{min_results} }

## output accessors ####################################################

# has verbose => (is => 'ro', default => 0)
sub verbose { my $self = shift;return $self->{verbose} || 0 }
sub has_verbose { my $self = shift; return exists $self->{verbose} }

# has verbose_data => (is => 'ro', default => 0)
sub verbose_data { my $self = shift;return $self->{verbose_data} || 0 }
sub has_verbose_data { my $self = shift; return exists $self->{verbose_data} }

########################################################################
# methods
########################################################################

# check the number of results returned from the database
sub number_of_results_ok {
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $self = shift;
  my $num_rows_from_db = @{ $self->db_results };

  # fail the test if we're running just one test and no matching row was
  # returned
  if(!$self->has_min_results &&
     !$self->has_max_results &&
     !$self->has_results &&
     $num_rows_from_db == 0) {
    return $self->_fail("No matching row returned");
  }

  # check we got the exected number of rows back if they specified exactly
  if($self->has_results && $num_rows_from_db != $self->results) {
    return $self->_fail("Got the wrong number of rows back from the database.",
                        "  got:      $num_rows_from_db rows back",
                        "  expected: @{[ $self->results ]} rows back");
  }

  # check we got enough matching rows back
  if($self->has_min_results && $num_rows_from_db < $self->min_results) {
    return $self->_fail("Got too few rows back from the database.",
                        "  got:      $num_rows_from_db rows back",
                         "  expected: @{[ $self->min_results ]} rows or more back");
  }

  # check we got didn't get too many matching rows back
  if($self->has_max_results && $num_rows_from_db > $self->max_results) {
      return $self->_fail("Got too many rows back from the database.",
                          "  got:      $num_rows_from_db rows back",
                          "  expected: @{[ $self->max_results ]} rows or fewer back");
  }

  return $self->_pass;
}

sub row_at_index_ok {
  my $self = shift;
  my $row_index  = shift || 0;

  # check we have data for this index
  my $row_index_th = ($row_index + 1) . _th($row_index + 1);
  my $data = $self->db_results->[ $row_index ];
  unless ($data)
    { return $self->_fail("No $row_index_th row") }

  # pass unless there's some tests to be run
  return $self->_pass unless $self->tests;

  # check each of the comparisons, sorted asciibetically
  foreach my $oper (sort keys %{ $self->tests }) {
    my $valuehash = $self->tests->{ $oper };

    # process each field in turn, sorted asciibetically
    foreach my $colname (sort keys %{$valuehash}) {

      # check the column we're comparing exists
      unless (exists($data->{ $colname })) {
        croak "No column '$colname' returned from table '@{[ $self->table ]}'"
          if $self->has_table;
        croak "No column '$colname' returned from sql";
      }



      # try the comparison
      my $expect = $valuehash->{ $colname };
      my $got    = $data->{ $colname };
      my $passed;
      {
        # disable warnings as we might compare undef
        local $SIG{__WARN__} = sub {}; # $^W not work

        # do a string eval because $oper could be any
        # arbitary comparison operator here.  Note the
        # the use of backslashes here so that we create
        # a string containing varaible names *not* the
        # values.
        eval "\$passed = \$got $oper \$expect; 1"
          or croak "Invalid operator test '$oper': $@";
      };

      unless ($passed) {
        return $self->_fail(
          "While checking column '$colname' on $row_index_th row",
          ( $oper =~ /\A (?:eq|==) \z/x )
            ? $self->_is_diag($got, $oper, $expect)
            : $self->_cmp_diag($got, $oper, $expect)
        );
      }
    }
  }

  return $self->_pass;
}

sub db_results_ok {
  my $self = shift;
  return $self->_pass unless $self->tests;
  foreach my $row_index (0..@{ $self->db_results }-1) {
    my $result = $self->row_at_index_ok( $row_index );
    return $result if $result->is_error;
    last unless $self->check_all_rows;
  }
  return $self->_pass;
}

sub test_ok {
  my $self = shift;
  my $result = $self->number_of_results_ok;
  return $result if $result->is_error;
  return $self->db_results_ok;
}

########################################################################
# methods for creating Test::DatabaseRow::Result objects
########################################################################

sub _pass {
  my $self = shift;
  return Test::DatabaseRow::Result->new();
}

sub _fail {
  my $self = shift;
  return Test::DatabaseRow::Result->new(
    is_error => 1,
    diag => [
      @_,

      # include the SQL diagnostics if we're verbose
      ($self->verbose ? $self->_sql_diag : ()),

      # include a dumper of the results if we're verbose_data
      ($self->verbose_data ?
        ("Data returned from the database:",$self->db_results_dumped)
        : ()
      ),
    ],
  );
}

 # prints out handy diagnostic text if we're printing out verbose text
sub _sql_diag {
  my $self = shift;

  my $database_name = $self->dbh->{Name};
  my ($sql, @bind) = @{ $self->sql_and_bind };

  my @diags;

  # print out the SQL
  push @diags, "The SQL executed was:";
  push @diags, map { "  $_\n" } split /\n/x, $sql;

  # print out the bound parameters
  if (@bind) {
    push @diags, "The bound parameters were:";
    foreach my $bind (@bind) {
      if (defined($bind)) {
        push @diags, "  '$bind'";
      } else {
        push @diags, "  undef";
      }
    }
  }

  # print out the database
  push @diags, "on database '$database_name'";

  return @diags;
}

# _cmp_diag and is__diag were originally private functions in
# Test::Builder (and were written by Schwern).

sub _cmp_diag {
  my($self, $got, $type, $expect) = @_;

  $got    = defined $got    ? "'$got'"    : 'undef';
  $expect = defined $expect ? "'$expect'" : 'undef';

  return sprintf <<"DIAGNOSTIC", $got, $type, $expect;
    %s
        %s
    %s
DIAGNOSTIC
}

sub _is_diag {
  my($self, $got, $type, $expect) = @_;

  foreach my $val (\$got, \$expect) {
    unless( defined ${$val} ) {
      ${$val} = 'NULL';
      next;
    }

    if( $type eq 'eq' ) {
      # quote and force string context
      ${$val} = "'${$val}'";
      next;
    }

    # otherwise force numeric context
    ${$val} = ${$val}+0;
  }

  return sprintf <<"DIAGNOSTIC", $got, $expect;
         got: %s
    expected: %s
DIAGNOSTIC
}

########################################################################
# stolen from Lingua::EN::Numbers::Ordinate
# Copyright (c) 2000 Sean M. Burke.  All rights reserved.
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# simple subroutine to 
sub _th {
  return 'th' if not(defined($_[0])) or not( 0 + $_[0] );
   # 'th' for undef, 0, or anything non-number.
  my $n = abs($_[0]);  # Throw away the sign.
  return 'th' unless $n == int($n); # Best possible, I guess.
  $n %= 100;
  return 'th' if $n == 11 or $n == 12 or $n == 13;
  $n %= 10;
  return 'st' if $n == 1;
  return 'nd' if $n == 2;
  return 'rd' if $n == 3;
  return 'th';
}

1;

__END__


=head1 NAME

Test::DatabaseRow::Object - examine database rows

=head1 SYNOPSIS

  use Test::More tests => 1;
  use Test::DatabaseRow::Object;
 
  # setup the test
  my $tdr = Test::DatabaseRow::Object->new(
    sql_and_bind => "SELECT * FROM contacts WHERE cid = '123'",
    tests        => [ name => "trelane" ],
  );

  # do the test and get a result back
  my $result_object = $tdr->tests_ok();

  # have those results render to Test::Builder
  $result_object->pass_to_test_builder("my database test");

=head1 DESCRIPTION

This module provides the underlying functionality of
C<Test::DatabaseRow>. 

=head2 Accessors

These are the read only accessors of the object.  They may be
(optionally) set at object creation time by passing their name
and value to the constructor.

Each accessor may be queried by prefixing its name with the
C<has_> to determine if it has been set or not.

=over

=item db_results

An arrayref of hashrefs, each representing a row returned from
the database.  Each key in the hashref should be the column name
and the value the corresponding field's value.  This
datastructure is identical to that.

If this accessor is not passed then it will be populated on
first use by executing the contents of C<sql_and_bind> against the
passed C<dbh>.

=item db_results_dumped

A string representation of the database results.

If this accessor is not passed then it will be populated on
first use by using Test::Builder's explain function on
C<db_results>

=item sql_and_bind

The SQL and bind variables to execute if no results were passed
into the db_results hash.  This should be an arrayref containing
the SQL as the first element and the bind values as further values.

This accessor will automatically coerce a simple scalar passed
in into a single 

If this accessor is not passed then it will be populated on
first use by building SQL from the C<where> and C<table> accessors.

=item dbh

The database handle used to execute the SQL statement in
C<sql_and_bind> if no C<db_results> were passed.

=item table

The table name used to build the SQL query if no value is
passed to C<sql_and_bind>.  String.

=item where

The data structure used to build the where clause of the SQL
query if no value is passed to <sql_and_bind>.

This accessor value should be a hashref of hashrefs, with the
outer keys being the SQL comparison operator, the inner keys
being the field names and the inner values being the values
to match against. For example:

  { 
    '='    => { first => "Fred", last => "Flintstone", },
    'like' => { address => "%Bedrock%" },
  }

Values of C<undef> will automatically converted into checks
for NULLs.

This accessor automatically coerces array refs that are
passed into a pure equals hashref.  For example:

  [ foo => "bar", bazz => "buzz" ]

Will be coerced into:

  { "=" => { foo => "bar", bazz => "buzz" } }

See L<Test::DatabaseRow/where> for a more detailed explanation.

=item verbose

Truth value, default false.  Controls if the diagnostic messages
printed during C<row_ok> on failure contain details of the SQL
executed or not.

=item verbose_data

Truth value, default false.  Controls if the diagnostic messages
printed during C<row_ok> on failure contain a Data::Dumper
style dump of the resulting rows from the database.

=item force_utf8

Truth value, default false.  Controls if the utf8 flag should be
turned on on values returned from the database.  See
L<Test::DatabaseRow/utf8 hacks> for why this might be important.

This flag only effects data that this module places into
C<db_resutls>.  If you manually populate this accessor this
flag will have no effect.

=item tests

If set, enables specified tests on the first element of
C<db_results> when C<row_ok> is called.

This accessor value should be a hashref of hashrefs, with the
outer keys being the Perl comparison operator, the inner keys
being the field names and the inner values being the values to
test against. For example:

  { 
    'eq' => { first => "Fred", last => "Flintstone", },
    '=~' => { address => "%Bedrock%" },
  }

This accessor automatically coerces array refs that are
passed into a hashref structure, converting things that look
like strings into C<eq> tests, things that look like numbers
into C<==> tests and things that are references to regular
expressions into C<=~> tests.  Foe example:

  [ num => 123, letters => "abc", kinda => qr/substring/ ]

Will be coerced into

  {
    '==' => { num => 123, },
    'eq' => { letters => "abc", },
    '=~' => { kinda => qr/substring/ },
  }

See L<Test::DatabaseRow/tests> for a more detailed explanation.

=item check_all_rows

Boolean to determine if we should test all rows (during
C<db_results_ok> and C<test_ok>) or just check the first
row.  Default true.

=item results

If set, enable tests to check the number of rows we returned by
C<db_results> is exactly this value when C<row_ok> is called.
Integer.

=item max_results

If set, enable tests to check the number of rows we returned by
C<db_results> is at most this value when C<row_ok> is called.
Integer.

=item min_results

If set, enable tests to check the number of rows we returned by
C<db_results> is at least this value when C<row_ok> is called.
Integer.

=back

=head2 Methods

=over

=item new(...)

Simple constructor.  Passing arguments to the constructor sets
the values of the accessors.

=item number_of_results_ok

Returns a Test::DatabaseRow::Result that represents if the
number of results in C<db_results> match the requirements
for the number of results.

=item row_at_index_ok( $row_index )

Returns a Test::DatabaseRow::Result that represents if the
element corresponding to the passed row index in C<db_results>
match the tests defined in C<tests>.

=item db_results_ok

Returns a Test::DatabaseRow::Result that represents if all
elements in C<db_results> match the tests defined in C<tests>.

=item test_ok

Returns a Test::DatabaseRow::Result that represents if the
number of results in C<db_results> match the requirements
for the number of results and  all
elements in C<db_results> match the tests defined in C<tests>.

=back

=head1 BUGS

Bugs (and requests for new features) can be reported though
the CPAN RT system:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-DatabaseRow>

Alternatively, you can simply fork this project on github and
send me pull requests.  Please see <http://github.com/2shortplanks/Test-DatabaseRow>

=head1 AUTHOR

Written by Mark Fowler B<mark@twoshortplanks.com>

Copyright Profero 2003, 2004.  Copyright Mark Fowler 2011.

Some code taken from B<Test::Builder>, written by Michael Schwern.
Some code taken from B<Regexp::Common>, written by Damian Conway.  Neither
objected to its inclusion in this module.

Some code taken from B<Lingua::EN::Numbers::Ordinate>, written by Sean M. Burke.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::DatabaseRow::Object>, L<Test::DatabaseRow::Result>, L<Test::More>, L<DBI>

=cut