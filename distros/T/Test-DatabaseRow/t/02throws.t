#!/usr/bin/perl -w

use strict;

# check if we can run Test::Exception
BEGIN
{
  eval { require Test::Exception; Test::Exception->import };
  if ($@)
  {
    print "1..0 # Skipped: no Test::Exception\n";
    exit;
  }
}

use Test::More tests => 17;
use Test::Exception;

use Test::DatabaseRow;

# check we get the correct error message
throws_ok { row_ok }
  qr/Needed fetch results but no 'dbh' defined/, "no dbh";

# define a new default database
$Test::DatabaseRow::dbh = FakeDBI->new;

# no table test
throws_ok { row_ok }
  qr/Needed to build SQL but no 'table' defined/, "no table";

# no where test
throws_ok { row_ok( table => "foo" ) }
  qr/Needed to build SQL but no 'where' defined/, "no where";

# bad where tests
throws_ok { row_ok( table => "foo",
                    where => \"wibble" ) }
  qr/Can't understand the argument passed in 'where'/, "bad where";

throws_ok { row_ok( table => "foo",
                    where => { foo => [ this => "wrong" ] } ) }
  qr/Can't understand the argument passed in 'where'/, "bad where 2";

# no tests - this is okay now
#throws_ok { row_ok( table => "foo",
#                    where => [ fooid => 123 ] ) }
#  qr/No 'tests' passed as an arguement/, "no tests";

# odd tests
throws_ok { row_ok( table => "foo",
                    where => [ fooid => 123 ] ,
                    tests => \"fish" ) }
  qr/Can't understand the argument passed in 'tests': not a hashref or arrayref/, "bad tests";

# odd tests
throws_ok { row_ok( table => "foo",
                    where => [ fooid => 123 ] ,
                    tests => { foo => [ bar => "baz" ] } );
          }
  qr/Can't understand the argument passed in 'tests': key 'foo' didn't contain a hashref/, "bad tests 2";

throws_ok { row_ok( table => "foo",
		    where => [ fooid => 123 ] ,
		    tests => [ notpresent => 1 ] )
	  }
  qr/No column 'notpresent' returned from table 'foo'/, "no col from build";

throws_ok { row_ok( sql   => "some sql",
		    tests => [ notpresent => 1 ] )
	  }
  qr/No column 'notpresent' returned from sql/, "no col from sql";

dies_ok { row_ok( dbh    => FakeDBI->new(fallover => 1, "hello" => "there"),
         	  sql    => "any old gumph",
	          tests  => [ fooid => 1 ]) } "handles problems with sql";

throws_ok { row_ok( db_results => [ { foo => "bar" } ],
                    tests => { invalidop => { foo => 'bar' } } ) }
  qr/Invalid operator test 'invalidop': \S+/, "invalid operator";

########################################################################
# bad SQL

throws_ok { row_ok( sql => \[] ) }
  qr/Can't understand the sql/;


########################################################################
# bad storage

throws_ok { row_ok( sql => "some sql", store_rows => {}) }
  qr/Must pass an arrayref in 'store_rows'/, "no col from sql";

throws_ok { row_ok( sql => "some sql", store_row => \"foo") }
  qr/Invalid argument passed in 'store_row'/, "no col from sql";

########################################################################
# Test::DatabaseRow::Object

{
  my $tdr = Test::DatabaseRow::Object->new(where => [ foo => "bar" ], table => "buzz" );
  throws_ok { $tdr->sql_and_bind }
    qr/Needed to quote SQL during SQL building but no 'dbh' defined/, "quote but no dbh"
}

{
  throws_ok {
    my $tdr = Test::DatabaseRow::Object->new( tests => [qw( a b c)] );
  }  qr/Can't understand the passed test arguments/, "odd tests"
}

########################################################################
# Test::DatabaseRow::Result

throws_ok { Test::DatabaseRow::Result->new( diag => {} ) }
  qr/Invalid argument to diag/, "diag invalid";

########################################################################

# fake database package
package FakeDBI;
use Data::Dumper;
sub new
{
  my $class = shift;
  return bless { @_ }, $class
}
sub quote { return "qtd<$_[1]>" };

sub prepare
{
  my $this = shift;

  # die if we need to
  if ($this->fallover)
    { die "Khaaaaaaaaaaaaan!" }

  return FakeSTH->new($this);
}

sub nomatch  { return $_[0]->{nomatch}  }
sub fallover { return $_[0]->{fallover} }

package FakeSTH;
sub new { return bless { parent => $_[1] }, $_[0] };
sub execute { return 1 };
sub fetchrow_hashref
{
  my $this = shift;
  my $parent = $this->{parent};

  # return undef after the first call)
  if ($this->{called})
    { return }
  else
    { $this->{called} = 1 }

  return
    ($parent->nomatch)
     ?  undef
     : { fooid => 123, name => "fred" }
}
