# Copyright (C) 2000-2006 Smithsonian Astrophysical Observatory
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=head1 NAME

Pg::Simple - simple OO interface to PostgreSQL

=head1 SYNOPSIS

  use Pg::Simple;

  my $db = new Pg::Simple;
  $db->connect( { DB => 'spectral' } );

  my $db = new Pg::Simple( { DB => 'spectral' } );

  $db->execute( SQL command or query ) or die;

  while ( $db->fetch( \$field1, \$field2 ) )
  { 
    print "$field1 $field2\n"
  }

  # or

  while ( $hash = $db->fetchhash and keys %$hash )
  {
    print $hash->{some_key};
  }

  $db->finish;

=head1 DESCRIPTION

B<Pg::Simple> is a very simple interface to PostgreSQL.  It is patterned after
the DBI interface.  Why not use the DBI interface instead?  The main
reason is that it does not yet support cursors.  This module does.  When
the DBI Postgres interface supports cursors, one should use that instead.

This module is designed primarily to ease reading data from a database.
All statements are executed within a transaction.  Normally the C<AutoCommit>
flag is set, meaning that after each execution of the B<do> or B<execute>
method, the backend is sent a C<commit> directive.  If C<AutoCursor> is
set, B<execute> will not perform a commit, as it would destroy the cursor.

Usually one uses the B<do> method for directives which do not return
any data.  The B<execute> and B<finish> pair should be used when data
is to be returned.  The main difference is that B<execute> will create
a cursor if C<AutoCursor> is set, while B<do> won't.  B<finish> is
required to close the cursor.

=head1 Object action methods

=over 4

=cut


package Pg::Simple;
use Pg;
use Carp;
use strict;
use vars qw( $VERSION );

$VERSION = '1.20';

=item new [ \%attr ]

This method creates a new B<Pg::Simple> object. It returns C<undef> upon error.
The optional hash of attributes may include any of the following:

=over 4

=item AutoCursor

If set, the B<execute> method always creates a cursor before sending the
command to the backend.  This defaults to on.

=item AutoCommit

If set, a C<commit> directive will be sent to the backend after each
B<do> is performed.  In order not to abort selections performed via
B<execute>, a C<commit> directive will I<not>
be sent to the backend by B<execute> if C<AutoCursor> is set.
It will be sent by the B<finish> method.
If not set, use the B<commit> method to commit any changes.  There is no
need to start a new transaction; that is done automatically.

=item RaiseError

If set, errors will result in an exception being thrown ( via
B<croak>), rather.  If not set, errors will result in a message being
printed to C<STDERR> and an error value returned to the caller.  It
defaults to on.

=item Verbose

If set, B<Pg::Simple> will say a few things about what it is doing (to STDERR).


=item NFetch

The number of tuples to fetch from the cursor at once.  This defaults to 1000.


=item Name

A symbolic name to assign to the connection.  This is used to differentiate
output when C<Verbose> is set.

=item Trace

If set (to a stream glob, i.e. C<\*STDERR>), the underlying C<Pg> interface
will send debugging information to that stream.  Defaults to off.

=item DB

The name of the database to which to connect.  If this is set, B<Pg::Simple>
will attempt to make a connection.  Alternatively, see the B<connect> method.

=item Host

The host to which to connect.  This defaults to the value of the C<PGHOST>
environmental variable, if that exists, else the undefined value.

=item Port

The port to which to connect.  This defaults to the value of the C<PGPORT>
environmental variable, if that exists, else C<5432>.

=item User

The database user id.

=item Password

The password to pass to the backend.  Required only if the database
requires password authentication.  If not specified, the value of the
C<PGPASSWORD> environmental variable is used.

=back


=cut

sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  
  my $self = {
	      attr => {
		       AutoCursor => 1,
		       AutoCommit => 1,
		       RaiseError => 1,
		       Verbose => 0,
		       NFetch => 1000,
		       Trace => undef,
		       Name => 'unknown'
		      },
	      db => {
		     DB => undef,
		     Host => $ENV{'PGHOST'} || undef,
		     Port => $ENV{'PGPORT'} || 5432,
		     User => $ENV{'USER'} || $ENV{'PGUSER'} || undef,
		     Password => $ENV{'PGPASSWORD'} || undef 
		    },
	      cursor => undef,
	      transaction => undef,
	      conn => undef,
	      result => undef,
	      last_tuple => undef,
	     };
  
  bless $self, $class;
  
  while ( @_ )
  {
    my $arg = shift;

    # hash of attributes
    if ( ref( $arg ) eq 'HASH' )
    {
      while ( my ( $key, $val ) = each ( %$arg ) )
      {
	if ( exists $self->{attr}->{$key} )
	{
	  $self->{attr}->{$key} = $val;
	}
	elsif ( exists $self->{db}->{$key} )
	{
	  $self->{db}->{$key} = $val;
	}
	else
	{
	  $self->_error( "Pg::Simple::new unknown attribute: $key\n" );
	  return undef;
	}
      }
    }
    else
    {
      $self->_error( "unacceptable argument to Pg::Simple::new\n" );
      return undef;
    }
  }
  
  if ( defined $self->{db}->{DB} )
  {
    $self->connect or return undef;
  }

  return $self;
}

sub DESTROY
{
  my $self = shift;

  # close cursor
  $self->finish;

  # close off old transaction
  $self->_msg( "commit" );
  $self->_exec( "commit", "couldn't commit transaction\n" );
}

=item connect([\%attr])

This method will connect to a database.  It takes an optional hash
which may contain the following attributes:

=over 4

=item DB

The name of the database to which to connect.  If this is set, B<Pg::Simple>
will attempt to make a connection.  Alternatively, see the B<connect> method.

=item Host

The host to which to connect.  This defaults to the value of the C<PGHOST>
environmental variable, if that exists, else the undefined value.

=item Port

The port to which to connect.  This defaults to the value of the C<PGPORT>
environmental variable, if that exists, else C<5432>.

=item User

The database user id.

=item Password

The password to pass to the backend.  Required only if the database
requires password authentication.  If not specified, the value of the
C<PGPASSWORD> environmental variable is used.

=back

It returns C<undef> upon error, else something else.

=cut

sub connect
{
  my $self = shift;
  my $attr = shift;

  my %db = ( %{$self->{db}}, $attr ? %$attr : () );

  my $connstr = "dbname=$db{DB} host=$db{Host} port=$db{Port}";
  $connstr .= " user=$db{User}"
    if $db{User};

  $connstr .= " password=$db{Password}"
    if $db{Password};

  $self->_msg( "opening connection `$connstr'" );
  $self->{conn} = Pg::connectdb( $connstr );

  if ( PGRES_CONNECTION_OK ne $self->{conn}->status )
  {
    $self->_error( "error opening connection: $connstr\n",
		   $self->{conn}->errorMessage, "\n" );
    $self->{conn} = undef;
    return undef;
  }
  if ( defined $self->{attr}->{Trace} )
  {
    $self->{conn}->trace( $self->{attr}->{Trace} );
  }

  # start transaction
  $self->_msg( "begin" );
  $self->_exec( "begin", "couldn't begin transaction\n" )
    or return undef;

  return $self->{conn};
}

=item execute( command [, \%attr] )

This method will pass a command or query to the backend.  
It may be passed a hash containing the following attributes:

=over 4

=item AutoCursor

If set, the B<execute> method always creates a cursor before sending the
command to the backend.  This defaults to on.

=item RaiseError

If set, errors will result in an exception being thrown ( via
B<croak>), rather.  If not set, errors will result in a message being
printed to C<STDERR> and an error value returned to the caller.  It
defaults to on.

=back

The attributes apply to this method call only.

It returns C<undef> upon error.

=cut


sub execute
{
  my $self = shift;
  my $exp = shift;
  my $attr = shift;

  my %attr = ( %{$self->{attr}}, $attr ? %$attr : () );

  local $self->{attr} = \%attr;

  if ( $attr{AutoCursor} )
  {
    $self->_msg( "declare mycursor cursor for $exp" );
    unless ( $self->_exec( "declare mycursor cursor for $exp", 
			   "couldn't create cursor for $exp\n" ) )
    {
      $self->abort;
      return undef;
    }
    $self->{cursor}++;
  }
  else
  {
    $self->_msg( "$exp" );
    $self->{result} = 
      $self->_exec( $exp, "error performing `$exp'\n" ) or
	( $self->abort, return undef );
    $self->{last_tuple} = -1;
    $self->commit if $self->{attr}->{AutoCommit};
  }

  1;
}

=item do( command [, \%attr] )

This method sends the command to the backend.  It does not create
a cursor. It may be passed a hash containing the following attributes:

=over 4

=item RaiseError

If set, errors will result in an exception being thrown ( via
B<croak>), rather.  If not set, errors will result in a message being
printed to C<STDERR> and an error value returned to the caller.  It
defaults to on.

=back

The attributes apply to this method call only.

It returns C<undef> upon error.

=cut


sub do
{
  my $self = shift;
  my $exp = shift;
  my $attr = shift;

  my %attr = ( %{$self->{attr}}, $attr ? %$attr : () );
  local $self->{attr} = \%attr;

  $self->_msg( "$exp" );
  $self->{result} = 
    $self->_exec( $exp, "error performing `$exp'\n" ) or
      ( $self->abort, return undef );
  $self->{last_tuple} = -1;

  $self->commit if $self->{attr}->{AutoCommit};

  1;
}

=item ntuples

The number of tuples returned by the last query.  It returns -1 if it
can't access that information.

=cut

sub ntuples
{
  my $self = shift;

  return $self->{result} ? $self->{result}->ntuples : -1;
}


=item fetch( \$field1, \$field2, ... )

Returns the next tuple of data generated by a previous call to
B<execute>.  If the C<AutoCursor> attribute was set, it will
internally fetch C<NFetch> tuples at a time.  It stores the returned
fields in the scalars referenced by the passed arguments.  It is an
error if there are fewer passed references than fields requested by
the select.

It returns 0 if there are no more tuples, C<undef> upon error.

=cut


sub fetch
{
  my $self = shift;

  my $result = $self->_fetch;

  return $result unless ref $result;

  if ( @_ != $result->nfields )
  {
    $self->_error("expected ", scalar @_, " got $result->{nfields}\n");
    return undef;
  }

  ${ shift @_ } = $_ foreach ( $result->fetchrow );

  1;
}

=item fetch_hashref

  $hash = $db->fetch_hasherf

Returns the next tuple of data generated by a previous call to
B<execute>.  If the C<AutoCursor> attribute was set, it will
internally fetch C<NFetch> tuples at a time.  It returns the row
as a hashref.

It returns an empty hash if there are no more tuples, C<undef> upon error.

=cut

sub fetch_hashref
{
  my $self = shift;

  my $result = $self->_fetch;

  if ( defined $result )
  {
    if ( ref $result )
    {
      @{$self->{hash}}{@{$self->{fname}}} = $result->fetchrow;
      return $self->{hash};
    }
    else
    {
      return {};
    }
  }

  return $result;
}

sub _fetch
{
  my $self = shift;

  my $result = $self->{result};
  my $tuple = ++$self->{last_tuple};

  # we're in a cursor
  if ( $self->{cursor} )
  {
    # check if there are still any left from a previous fetch

    if ( ! defined $result || $tuple >= $result->ntuples )
    {
      # delete old results and reset tuple counter
      $self->{result} = undef;
      $self->{last_tuple} = -1;

      # get new results
      my $fetch = "fetch $self->{attr}->{NFetch} in mycursor";
      $self->_msg( $fetch );
      $result = $self->_exec( $fetch, "couldn't fetch\n" ) 
	or return undef;

      return 0 
	unless $result->ntuples;

      # succeeded, save result
      $self->{result} = $result;

      unless ( defined $self->{fname} )
      {
	my @fnames;
	push @fnames, $result->fname($_) for 0.. $result->nfields-1;
	$self->{fname} = \@fnames;
	$self->{hash} = {};
	@{$self->{hash}}{@fnames} = (undef) x @fnames;
      }

      $tuple = $self->{last_tuple} = 0;
    }
  }

  # not in a cursor
  else
  {
    return 0
      if $tuple >= $result->ntuples;
  }

  $result;
}


sub _exec
{
  my $self = shift;
  my $exp  = shift;
  my $errmsg = shift;

  my $result = $self->{conn}->exec( $exp );
  if ( 
      PGRES_COMMAND_OK != $result->resultStatus and
      PGRES_TUPLES_OK != $result->resultStatus
     )
  {
    $self->_error( $errmsg );
    return undef;
  }
  return $result;
}

=item commit

This should be called to commit any changes to the database.

=cut

sub commit
{
  my $self = shift;

  # close off old transaction
  $self->_msg( "commit" );
  $self->_exec( "commit", "couldn't commit transaction\n" );

  # start a new one
  $self->_msg( "begin" );
  $self->_exec( "begin", "couldn't begin transaction\n" );
}

=item abort

This should be called to abort the current transaction

=cut

sub abort
{
  my $self = shift;

  # close off old transaction
  $self->_msg( "abort" );
  $self->_exec( "abort", "couldn't abort transaction\n" );

  # start a new one
  $self->_msg( "begin" );
  $self->_exec( "begin", "couldn't begin transaction\n" );
}


=item finish

This should be called after all fetchs have been completed for a 
select statement. It closes the cursor (if C<AutoCursor> was specified).

=cut

sub finish
{
  my $self = shift;

  if ( $self->{cursor} )
  {
    $self->_msg( "close mycursor" );
    $self->_exec( "close mycursor", "couldn't close cursor\n" );
    $self->{cursor} = 0;
  }

  $self->commit if $self->{attr}->{AutoCommit};

}

sub _error
{
  my $self = shift;

  if ( $self->{attr}{RaiseError} )
  {
    croak @_;
  }
  else
  {
    carp @_;
  }
}

sub _msg
{
  my $self = shift;

  warn $self->{attr}{Name}, ': ', @_, "\n"
    if $self->{attr}{Verbose};
}


1;

=back

=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at 

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius ( djerius@cpan.org )


=cut
