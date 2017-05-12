package Test::DatabaseRow;

# require at least a version of Perl that is merely ancient, but not
# prehistoric
use 5.006;

use strict;
use warnings;

# set row_ok to be exported
use base qw(Exporter);
our @EXPORT;

use Carp qw(croak);
our @CARP_OK = qw(Test::DatabaseRow TestDatabaseRow::Object);

# set the version number
our $VERSION = "2.04";

use Test::DatabaseRow::Object;
our $object_class = "Test::DatabaseRow::Object";

sub row_ok {

  # horrible, horrible package vars
  # In 2003 Mark Fowler chose to make a procedual interface
  # to this module and keep state in package vars to make the
  # interface easy.  In 2011 Mark Fowler isn't sure this is
  # a great idea
  our $dbh;
  our $force_utf8;
  our $verbose;
  our $verbose_data;

  # defaults
  my %args = (
    dbh => $dbh,
    force_utf8 => $force_utf8,
    verbose => $verbose || $ENV{TEST_DBROW_VERBOSE},
    verbose_data => $verbose_data || $ENV{TEST_DBROW_VERBOSE_DATA},
    check_all_rows => 0,
  @_ );

  # rename "sql" to "sql_and_bind"
  # (it's called just sql for legacy reasons)
  $args{sql_and_bind} = $args{sql}
    if exists $args{sql} && !exists $args{sql_and_bind};

  # remove description, provide default fallback from label
  my $label       = delete $args{label};
  my $description = delete $args{description};
  $description = $label unless defined $description;
  $description = "simple db test" unless defined $description;

  # do the test
  my $tbr = $object_class->new(%args);
  my $tbr_result = $tbr->test_ok();

  # store the results of the database operation in a var passed
  # into this function.
  # 
  # This is another example of functionality that is difficult
  # to add to a procedural interface and would have been easier
  # if I'd used an OO interface.  That's the problem with
  # published APIs though, isn't it?  It's hard to change them
  if ($args{store_rows}) {
    croak "Must pass an arrayref in 'store_rows'"
      unless ref $args{store_rows}  eq "ARRAY";
    @{ $args{store_rows} } = @{ $tbr->db_results };
  }
  if ($args{store_row}) {
    if (ref $args{store_row} eq "HASH") {
      %{ $args{store_row} } = %{ $tbr->db_results->[0] };
    } elsif (ref $args{store_row} eq "SCALAR" && !defined ${ $args{store_row} }) {
      ${ $args{store_row} } = $tbr->db_results->[0];
    } elsif (ref $args{store_row} eq "REF" && ref ${ $args{store_row} } eq "HASH" ) {
      %{${ $args{store_row} }} = %{ $tbr->db_results->[0] };
    } else {
      croak "Invalid argument passed in 'store_row'";
    }
  }

  # render the result with Test::Builder
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return $tbr_result->pass_to_test_builder( $description );
}
push @EXPORT, qw(row_ok);

sub not_row_ok {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return row_ok(@_, results => 0);
}
push @EXPORT, qw(not_row_ok);

sub all_row_ok {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return row_ok(@_, check_all_rows => 1);
}
push @EXPORT, qw(all_row_ok);


# truth at end of the module
1;

__END__

=head1 NAME

Test::DatabaseRow - simple database tests

=head1 SYNOPSIS

  use Test::More tests => 3;
  use Test::DatabaseRow;

  # set the default database handle
  local $Test::DatabaseRow::dbh = $dbh;

  # sql based test
  all_row_ok(
    sql   => "SELECT * FROM contacts WHERE cid = '123'",
    tests => [ name => "trelane" ],
    description => "contact 123's name is trelane"
  );

  # test with shortcuts
  all_row_ok(
    table => "contacts",
    where => [ cid => 123 ],
    tests => [ name => "trelane" ],
    description => "contact 123's name is trelane"
  );

  # complex test
  all_row_ok(
    table => "contacts",
    where => { '='    => { name   => "trelane"            },
               'like' => { url    => '%shortplanks.com'   },},
    tests => { '=='   => { cid    => 123,
                           num    => 134                  },
               'eq'   => { person => "Mark Fowler"        },
               '=~'   => { road   => qr/Liverpool R.?.?d/ },},
    description => "trelane entered into contacts okay" );
  );

=head1 DESCRIPTION

This is a simple module for doing simple tests on a database, primarily
designed to test if a row exists with the correct details in a table or
not.

This module exports several functions.

=head2 row_ok

The C<row_ok> function takes named attributes that control which rows
in which table it selects, and what tests are carried out on those rows.

By default it performs the tests against only the first row returned
from the database, but parameters passed to it can alter that
behavior.

=over 4

=item dbh

The database handle that the test should use.  In lieu of this
attribute being passed the test will use whatever handle is set
in the C<$Test::DatabaseRow::dbh> global variable.

=item sql

Manually specify the SQL to select the rows you want this module to execute.

This can either be just a plain string, or it can be an array ref with the
first element containing the SQL string and any further elements containing
bind variables that will be used to fill in placeholders.

  # using the plain string version
  row_ok(sql   => "SELECT * FROM contacts WHERE cid = '123'",
         tests => [ name => "Trelane" ]);

  # using placeholders and bind variables
  row_ok(sql   => [ "SELECT * FROM contacts WHERE cid = ?", 123 ],
         tests => [ name => "Trelane" ]);

=item table

Build the SELECT statement programmatically.  This parameter contains the name
of the table the  SELECT statement should be executed against.  You cannot
pass both a C<table> parameter and a C<sql> parameter.  If you specify
C<table> you B<must> pass a C<where> parameter also (see below.)

=item where

Build the SELECT statement programmatically.  This parameter should contain
options that will combine into a WHERE clause in order to select the row
that you want to test.

This options normally are a hash of hashes.  It's a hashref keyed by SQL
comparison operators that has in turn values that are further hashrefs
of column name and values pairs.  This sounds really complicated, but
is quite simple once you've been shown an example.  If we could get
get the data to test with a SQL like so:

  SELECT *
    FROM tablename
   WHERE foo  =    'bar'
     AND baz  =     23
     AND fred LIKE 'wilma%'
     AND age  >=    18

Then we could have the function build that SQL like so:

  row_ok(table => "tablename",
         where => { '='    => { foo  => "bar",
                                baz  => 23,       },
                    'LIKE' => { fred => 'wimla%', },
                    '>='   => { age  => '18',     },});

Note how each different type of comparison has it's own little hashref
containing the column name and the value for that column that the
associated operator SQL should search for.

This syntax is quite flexible, but can be overkill for simple tests.
In order to make this simpler, if you are only using '=' tests you
may just pass an arrayref of the column names / values.  For example,
just to test

  SELECT *
    FROM tablename
   WHERE foo = 'bar'
     AND baz = 23;

You can simply pass

  row_ok(table => "tablename",
         where => [ foo  => "bar",
                    baz  => 23,    ]);

Which, in a lot of cases, makes things a lot quicker and simpler to
write.

NULL values can confuse things in SQL.  All you need to remember is that
when building SQL statements use C<undef> whenever you want to use a
NULL value.  Don't use the string "NULL" as that'll be interpreted as
the literal string made up of a N, a U and two Ls.

As a special case, using C<undef> either in a C<=> or in the short
arrayref form will cause a "IS" test to be used instead of a C<=> test.
This means the statements:

  row_ok(table => "tablename",
         where => [ foo  => undef ],)

Will produce:

  SELECT *
    FROM tablename
   WHERE foo IS NULL

=item tests

The comparisons that you want to run between the expected data and the
data in the first line returned from the database.  If you do not
specify any tests then the test will simply check if I<any> rows are
returned from the database and will pass no matter what they actually
contain.

Normally this is a hash of hashes in a similar vein to C<where>.
This time the outer hash is keyed by Perl comparison operators, and
the inner hashes contain column names and the expected values for
these columns.  For example:

  row_ok(sql   => $sql,
         tests => { "eq" => { wibble => "wobble",
                              fish   => "fosh",    },
                    "==" => { bob    => 4077       },
                    "=~" => { fred   => qr/barney/ },},);

This checks that the column wibble is the string "wobble", column fish
is the string "fosh", column bob is equal numerically to 4077, and
that fred contains the text "barney".  You may use any infix
comparison operator (e.g. "<", ">", "&&", etc, etc) as a test key.

The first comparison to fail (to return false) will cause the whole
test to fail, and debug information will be printed out on that comparison.

In a similar fashion to C<where> you can also pass a arrayref for
simple comparisons.  The function will try and Do The Right Thing with
regard to the expected value for that comparison.  Any expected value that
looks like a number will be compared numerically, a regular expression
will be compared with the C<=~> operator, and anything else will
undergo string comparison.  The above example therefore could be
rewritten:

  row_ok(sql   => $sql,
         tests => [ wibble => "wobble",
                    fish   => "fosh",
                    bob    => 4077,
                    fred   => qr/barney/ ]);

=item check_all_rows

Setting this to a true value causes C<row_ok> to run the tests
against all rows returned from the database not just the first.

=item verbose

Setting this option to a true value will cause verbose diagnostics to
be printed out during any failing tests.  You may also enable this
feature by setting either C<$Test::DatabaseRow::verbose> variable or the
C<TEST_DBROW_VERBOSE> environmental variable to a true value.

=item verbose_data

Setting this option to a true value will cause the results of running
the SQL queries to be printed out during any failing tests.  You may
also enable this feature by setting either
C<$Test::DatabaseRow::verbose_data> variable or the
C<TEST_DBROW_VERBOSE_DATA> environmental variable to a true value.

=item store_rows

Sometimes, it's not enough to just use the simple tests that
B<Test::DatabaseRow> offers you.  In this situation you can use the
C<store_rows> function to get at the results that row_ok has extracted
from the database.  You should pass a reference to an array for the
results to be stored in;  After the call to C<row_ok> this array
will be populated with one hashref per row returned from the database,
keyed by column names.

  row_ok(sql => "SELECT * FROM contact WHERE name = 'Trelane'",
         store_rows => \@rows);

  ok(Email::Valid->address($rows[0]{'email'}));

=item store_row

The same as C<store_rows>, but only the stores the first row returned
in the variable.  Instead of passing in an array reference you should
pass in either a reference to a hash...

  row_ok(sql => "SELECT * FROM contact WHERE name = 'Trelane'",
         store_rows => \%row);

  ok(Email::Valid->address($row{'email'}));

...or a reference to a scalar which should be populated with a
hashref...

  row_ok(sql => "SELECT * FROM contact WHERE name = 'Trelane'",
         store_rows => \$row);

  ok(Email::Valid->address($row->{'email'}));

=item description

The description that this test will use with C<Test::Builder>,
i.e the thing that will be printed out after ok/not ok.
For example:

  row_ok(
    sql => "SELECT * FROM queue",
    description => "something in the queue"
  );

Hopefully produces something like:

  ok 1 - something in the queue

For historical reasons you may also pass C<label> for this
parameter.

=back

=head2 Checking the number of results

By default C<row_ok> just checks the first row returned from the
database matches the criteria passed.  By setting the parameters below
you can also cause the module to check that the correct number of rows
are returned from by the select statement (though only the first row
will be tested against the test conditions.)

=over 4

=item results

Setting this parameter causes the test to ensure that the database
returns exactly this number of rows when the select statement is
executed.  Setting this to zero allows you to ensure that no matching
rows were found by the database, hence this parameter can be used
for negative assertions about the database.

  # assert that Trelane is _not_ in the database
  row_ok(sql     => "SELECT * FROM contacts WHERE name = 'Trelane'",
         results => 0 );

  # convenience function that does the same thing
  not_row_ok(sql => "SELECT * FROM contacts WHERE name = 'Trelane'")

=item min_results / max_results

This parameter allows you to test that the database returns
at least or no more than the passed number of rows when the select
statement is executed.

=back

=cut

=head2 Convenience Functions  

This module also exports a few convenience functions that make
using certain features of C<row_ok> more straight forward.

=over

=item all_row_ok

The C<all_row_ok> function is shorthand notation for "Check every
row returned from the database not just the first"

For example:

  all_row_ok(tests => { ">=" => { age => "18" } }, sql => <<'SQL');
    SELECT *
      FROM drinkers
     WHERE country = 'uk'
  SQL

Checks to see that all drinkers from the UK are over 18.  It's
identical to having written:

  row_ok(tests => { ">=" => { age => "18" } },
         check_all_rows => 1, sql => <<'SQL');
    SELECT *
      FROM drinkers
     WHERE country = 'uk'
  SQL

=item not_row_ok

The C<not_row_ok> function is shorthand notation for "the database
returned no rows when I executed this SQL".

For example:

  not_row_ok(sql => <<'SQL');
    SELECT *
      FROM languages
     WHERE name = 'Java'
  SQL

Checks to see the database doesn't have any rows in the language
table that have a name "Java".  It's exactly the same as if
we'd written:

  row_ok(sql => <<'SQL', results => 0);
    SELECT *
      FROM languages
     WHERE name = 'Java'
  SQL

=back

=head2 Other SQL modules

The SQL creation routines that are part of this module are designed
primarily with the concept of getting simple single rows out of the
database with as little fuss as possible.  This having been said, it's
quite possible that you need to use a more complicated SQL generation
scheme than the one provided.

This module is designed to work (hopefully) reasonably well with the
other modules on CPAN that can automatically create SQL for you.  For
example, B<SQL::Abstract> is a module that can manufacture much more
complex select statements that can easily be 'tied in' to C<row_ok>:

  use SQL::Abstract;
  use Test::DatabaseRow;
  my $sql = SQL::Abstract->new();

  # more complex routine to find me heuristically by looking
  # for any one of my nicknames and my street address
  row_ok(sql   => [ $sql->select("contacts",
                                 "*",
                                 { name => [ "Trelane",
                                             "Trel",
                                             "MarkF" ],
                                   road => { 'like' => "Liverpool%" },
                                 })],
         tests => [ email => 'mark@twoshortplanks.com' ],
         description => "check mark's email address");

=head2 utf8 hacks

Often, you may store data utf8 data in your database.  However, many
modern databases still do not store the metadata to indicate the data
stored in them is utf8 and their DBD drivers may not set the utf8 flag
on values returned to Perl.  This means that data returned to Perl
will be treated as if it is encoded in your normal character set
rather than being encoded in utf8 and when compared to a byte for
byte an identical utf8 string may fail comparison.

    # this will fail incorrectly on data coming back from
    # mysql since the utf8 flags won't be set on returning data
    use utf8;
    row_ok(sql   => $sql,
           tests => [ name => "Napol\x{e9}on" ]);

The solution to this is to use C<Encode::_utf_on($value)> on each
value returned from the database, something you will have to do
yourself in your application code.  To get this module to do this for
you you can either pass the C<force_utf8> flag to C<row_ok>.

    use utf8;
    row_ok(sql        => $sql,
           tests      => [ name => "Napol\x{e9}on" ],
           force_utf8 => 1);

Or set the global C<$Test::DatabaseRow::force_utf8> variable

   use utf8;
   local $Test::DatabaseRow::force_utf8 = 1;
   row_ok(sql        => $sql,
          tests      => [ name => "Napol\x{e9}on" ]);

Please note that in the above examples with C<use utf8> enabled I
could have typed Unicode eacutes into the string directly rather than
using the C<\x{e9}> escape sequence, but alas the pod renderer you're
using to view this documentation would have been unlikely to render
those examples correctly, so I didn't.

Please also note that if you want the debug information that this
module creates to be rendered to STDERR correctly for your utf8
terminal then you may need to stick

   binmode STDERR, ":utf8";

At the top of your script.

=head2 Using a custom object subclass

This procedural wrapper relies on the base functionality of
C<Test::DatabaseRow::Object> to do the actual work.  If you want
to subclass that class (for example to use an alternative method
of accessing the database) but continue to use this wrapper
class you can do so by setting the C<$Test::DatabaseRow::object_class>
variable.

For example:

   local $Test::DatabaseRow::object_class =
     "Test::DatabaseRow::Object::MyFunnySubclassOrOther";
   row_ok(
     sql => "SELECT * FROM qa WHERE a = '42'",
   );

=head1 BUGS

You I<must> pass a C<sql> or C<where> argument to limit what is
returned from the table.  The case where you don't want to is so
unlikely (and it's much more likely that you've written a bug in your
test script) that omitting both of these is treated as an error.  If
you I<really> need to not pass a C<sql> or C<where> argument, do C<< where
=> [ 1 => 1 ] >>.

Passing shared variables (variables shared between multiple threads
with B<threads::shared>) in with C<store_row> and C<store_rows> and
then changing them while C<row_ok> is still executing is just asking
for trouble.

The utf8 stuff only really works with perl 5.8 and later.  It just
goes horribly wrong on earlier perls.  There's nothing I can do to
correct that.  Also, no matter what version of Perl you're running,
currently no way provided by this module to force the utf8 flag to be
turned on for some fields and not on for others.

The inbuilt SQL builder always assumes you mean C<IS NULL> not
C<= NULL> when you pass in C<undef> in a C<=> section

Bugs (and requests for new features) can be reported though the CPAN
RT system:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-DatabaseRow>

Alternatively, you can simply fork this project on github and
send me pull requests.  Please see L<http://github.com/2shortplanks/Test-DatabaseRow>

=head1 AUTHOR

Written by Mark Fowler B<mark@twoshortplanks.com>

Copyright Profero 2003, 2004.  Copyright Mark Fowler 2011.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::DatabaseRow::Object>, L<Test::More>, L<DBI>

=cut