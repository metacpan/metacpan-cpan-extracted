# For Emacs: -*- mode:cperl; mode:folding -*-

package SQLite::DB;

# {{{ BEGIN
#
BEGIN {
  require Exporter;
}
# }}}
# {{{ use block
#
use strict;
use Exporter;
use DBI;
use DBD::SQLite;

use constant { INVALID => 0,     # SQL Statment types
               SELECT  => 1,
               INSERT  => 2,
	       UPDATE  => 3,
	       DELETE  => 4,
	       CREATE  => 5,
	       DROP    => 6,};

use base 'Exporter';

# }}}
# {{{ variable declarations

our @ISA = ('Exporter');
our @EXPORT = qw(connect disconnect transaction_mode commit exec
             select get_dboptionlist get_dblist get_error);

our $VERSION    = '0.04';

my $last_rowid         = undef;
my $affected_rows      = 0;
my @transaction_errors;

# }}}

# {{{ new                               Object Constructor
#
# Creates object based on given dbfile.
#
sub new {
  my $class = shift;
  my $self  = { dbfile	  => shift,
	        dbconn	  => undef,
	        dberror   => undef,};

  bless $self,$class;

  return $self;
}
# }}}
# {{{ connect                           Connect to the database
#
# Returns 1 if sucessfull, 0 otherwise.
#
sub connect {
  my $this = shift;
  my $db   = DBI->connect("dbi:SQLite:dbname=".$this->{dbfile},"","");

  $db->{PrintError} = 0;
  $db->{RaiseError} = 0;

  return 0 if ($this->check_error(__PACKAGE__."::connect - Error while connecting to DBI :"));

  if (!defined $db) {
    $this->{dberror} = "Cannot connect to databases: $DBI::errstr\n";
    return 0;
  }

  $this->{dbconn} = $db;

  return 1;
}
# }}}
# {{{ disconnect                        Diconnect to the database
#
sub disconnect {
  my $this = shift;

  $this->{dbconn}->disconnect || return 0;
  $this->{dbconn} = undef;

  return 1;
}
# }}}
# {{{ transaction_mode                  Start transaction mode
#
sub transaction_mode {
  my $this = shift;

  @transaction_errors = ();
  $this->{dbconn}->{AutoCommit} = 0;

}
# }}}
# {{{ commit                            Commit transaction
#
sub commit {
  my $this   = shift;
  my $result = 1;
  my $error;
  return 1 if ($this->{dbconn}->{AutoCommit});

  eval { $this->{dbconn}->commit } if !(@transaction_errors>0);

  if ($@ || @transaction_errors>0) { # Check if errors occurred in the transaction
    $result          = 0;
    $error           = ($@) ? $@ : join "\n",@transaction_errors;
    $this->{dberror} = "DBSqlite::DB::commit - Error in transaction because $error";
    eval {$this->{dbconn}->rollback};
  }

  $this->{dbconn}->{AutoCommit} = 1;

  return $result;
}

# }}}
# {{{ rollback                          Rollback transaction
#
sub rollback {
  my $this   = shift;
  my $result = 1;

  return 1 if ($this->{dbconn}->{AutoCommit});

  $this->{dbconn}->rollback;

  if ($@) {                             # Check if errors occurred in the transaction
    $result          = 0;
    $this->{dberror} = "DBSqlite::DB::rollback - Error in transaction because $@\n ";
  }

  $this->{dbconn}->{AutoCommit} = 1;

  return $result;
}

# }}}
# {{{ exec                              Execute an query
#
# You can pass bind array as arguments.
#
sub exec {
  my $this  = shift;
  my $query = shift;
  my @bind  = @_;
  my $type  = get_sql_type($query);
  my $sth;
  my $rv;

  $last_rowid    = undef;
  $affected_rows = 0;

  if (!defined $this->{dbconn}) {
    $this->{dberror} = __PACKAGE__."::exec_query - DB handle not defined";
    return 0;
  }

  $sth = $this->{dbconn}->prepare($query);
  return 0 if ($this->check_error(__PACKAGE__."::exec_query - Error while preparing :"));

  $rv = $sth->execute(@bind);
  return 0 if ($this->check_error(__PACKAGE__."::exec_query - Error while executing :"));

  $last_rowid = $this->{dbconn}->func('last_insert_rowid') if ($type == INSERT);

  if (($type == DELETE || $type == UPDATE) && $rv != 0E0) {
    $affected_rows = $rv;
  }

  $sth->finish;

  return 1;
}
# }}}
# {{{ last_insert_rowid                 Returns the last inserted row id
#
sub last_insert_rowid {
  return $last_rowid;
}
# }}}
# {{{ get_affected_rows                 Returns the number of affected rows from last exec
#
sub get_affected_rows {
  return $affected_rows;
}
# }}}
# {{{ select                            Execute an select query
#
# You can pass bind arguments.
#
sub select {
  my $this    = shift;
  my $query   = shift;
  my $funcptr = shift;
  my @bind    = @_;
  my $sth;

  if (!defined $this->{dbconn}) {
    $this->{dberror} = __PACKAGE__."::select_query - DB handle not defined";
    return 0;
  }

  $sth = $this->{dbconn}->prepare($query);
  return 0 if ($this->check_error(__PACKAGE__."::select_query - Error while preparing :"));

  $sth->execute(@bind);
  return 0 if ($this->check_error(__PACKAGE__."::select_query - Error while executing :"));

  $funcptr->($sth) if (defined $funcptr);

  $sth->finish;

  return 1;
}
# }}}
# {{{ select_one_row                    Execute an select query returnin only one row as an hash
#
sub select_one_row {
  my $this   = shift;
  my $query  = shift;
  my @bind   = @_;
  my $result = undef;

  $this->select($query,
		sub { my $sth = (defined $_[0]) ? shift : return;
		      $result = $sth->fetchrow_hashref || return;},
		@bind);

  return $result;
}
# }}}
# {{{ get_dblist                        Returns an array representing the resultset
#
# Each result contains key and value
#
sub get_dblist {
  my $this  	   = shift;
  my $query        = shift;
  my $displayfield = shift;
  my $keyfield 	   = shift;
  my $result       = [];
  my $id	   = 0;
  my $sth;

  if (!defined $this->{dbconn}) {
    $this->{dberror} = __PACKAGE__."::get_dblist - DB handle not defined";
    return 0;
  }

  $sth = $this->{dbconn}->prepare($query);
  return 0 if ($this->check_error(__PACKAGE__."::get_dblist - Error while preparing :"));

  $sth->execute;
  return 0 if ($this->check_error(__PACKAGE__."::get_dblist - Error while executing :"));

  while (my $data = $sth->fetchrow_hashref) {               # Go through the records
    $result->[$id]->{id}    = $$data{$keyfield};
    $result->[$id]->{value} = $$data{$displayfield};
    $id++;
  }

  $sth->finish;

  return $result;
}
# }}}
# {{{ get_error                         Return last db error
#
sub get_error {
  my $this = shift;

  return $this->{dberror};
}
# }}}
# {{{ check_error                       Check if an error occured
#
# Save the error in dberror var.
#
sub check_error {
  my $this   = shift;
  my $err_id = shift;
  my $query  = shift;

  if ($DBI::err || $DBI::errstr) {
    $this->{dberror}  = $err_id."\n";
    $this->{dberror} .= "SQL : ".$query."\n" if (defined $query);
    $this->{dberror} .= "Errors: $DBI::err, $DBI::errstr\n";
    push @transaction_errors,$this->{dberror};
    return 1;
  }

  return 0;
}
# }}}
# {{{ get_sql_type                      Get the type of an sql statment
#
sub get_sql_type {
  my $this   = (ref $_[0]) ? shift : undef;
  my $query  = shift;

  return SELECT if ($query =~ /^\s*SeLeCt/i);
  return INSERT if ($query =~ /^\s*InSeRt/i);
  return UPDATE if ($query =~ /^\s*UpDaTe/i);
  return DELETE if ($query =~ /^\s*DeLeTe/i);
  return CREATE if ($query =~ /^\s*CrEaTe/i);
  return DROP   if ($query =~ /^\s*DrOp/i);

  return INVALID;
}
# }}}

1;

# {{{ module documentation

__END__

=head1 NAME

SQLite::DB provides an object oriented wrapper to SQLite databases using
DBI and DBD::SQLite modules.

=head1 SYNOPSIS

 use SQLite::DB;

 my $db = SQLite::DB->new('file');

 $db->connect;

 $db->select("select * from table where field = value",{}) || print $db->get_error."\n";

 $db->select("select * from table where field = ?",{},"value") || print $db->get_error."\n";

 $result = $db->select_one_row("select max(field) as total FROM table");

 print $$result{TOTAL};

 $db->transaction_mode;

 $db->exec("INSERT (a,b,c) VALUES 'a','b','c'");
 $db->exec("INSERT (a,b,c) VALUES ?,?,?",'a','b','c');
 $db->exec("update table set field = value") || print $db->get_error."\n";

 $db->commit || print $db->get_error."\n";
 $db->rollback || print $db->get_error."\n";

 my $resultset = $db->get_dblist("select * from table","display_field","keyfield");

 if (!ref $resultset) {
   print $db->get_error."\n"
 } else {
   for (@$resultset) {
     print $resultset->[$_]->{id}." - ".$resultset->[$_]->{value}."\n";
   }
 }

 $db->disconnect;

=head1 DESCRIPTION

The goal is provide simple coding style to interact with SQLite databases.

=head1  CLASSES

SQLite::DB

=head1 USE

DBI, DBD:SQLite

=head1 CLASS METHODS

=head2 new($path)

Construtor. $path is the full path to the db file.

=head2 connect

Connect to the database. If it does not exists, it created an new database.

=head2 disconnect

Disconnect to the database.

=head2 transaction_mode

Define transaction mode. No commits will be done until get the commit function.

=head2 commit

Commit an transaction. If is not in transaction mode, nothing happens.

=head2 rollback

Rollback an transaction. If is not in transaction mode, nothing happens.

=head2 exec($query,[@args...])

Execute an query. Optional argumens are used when you want to bind params of your query.

=head2 select($query,$funcptr,[@args...])

Execute an select query.

$funcptr is an callback function pointer that received $sth object as argument, to process the rows of the select query.

Optional argumens are used when you want to bind params of your query.

=head2 select_one_row($query)

Provides an easier way to retrieve one row queries. It returns an hash with field/values of the query.

=head2 get_dblist($query,$display_field,$keyfield)

Provided an easier way to retrive two columns queries.

It returns an array with hash itens with "id" and "value" itens.

=head2 get_error

Return last error.

$head2 get_affected_rows

Return the number of affected rows from the last exec query.

=back

=head1 INTERNAL METHODS

=item * check_error

This method provide an common way to check DBI/DBD errors.

=item * get_sql_type

This returns the type of an query.

=head1 EXPORT

$item * last_insert_rowid

Stores the last insert rowid.

=head1 KNOWN BUGS

None.

=head1 AUTHOR

Vitor Serra Mori E<lt>vvvv767@hotmail.com.E<gt>

=head1 COPYRIGHT

This package is free software. Tou can redistribute and/or modify it under
the same terms as Perl itself.

# }}}
