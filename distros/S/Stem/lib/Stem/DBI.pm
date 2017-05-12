#  File: Stem/DBI.pm

#  This file is part of Stem.
#  Copyright (C) 1999, 2000, 2001 Stem Systems, Inc.

#  Stem is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.

#  Stem is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with Stem; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#  For a license to use the Stem under conditions other than those
#  described here, to purchase support for this software, or to purchase a
#  commercial warranty contract, please contact Stem Systems at:

#       Stem Systems, Inc.		781-643-7504
#  	79 Everett St.			info@stemsystems.com
#  	Arlington, MA 02474
#  	USA

package Stem::DBI ;

use strict ;

use DBI ;

use base 'Stem::Cell' ;
use Stem::Route qw( :cell ) ;


my $attr_spec = [

	{
		'name'		=> 'reg_name',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'port',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'host',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'db_type',
		'required'	=> 1,
		'help'		=> <<HELP,
HELP
	},

        # db_name must be something that can go after "dbi:mysql:" so
        # something like "dbname=foo" or "database=foo" depending on
        # the driver.
	{
		'name'		=> 'db_name',
		'required'	=> 1,
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'user_name',
		'env'		=> 'dbi_user_name',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'password',
		'env'		=> 'dbi_password',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'dsn_extras',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'statements',
		'help'		=> <<HELP,
HELP
	},
	{
		'name'		=> 'error_log',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'default_return_type',
	        'default'       => 'list_of_hashes',
		'help'		=> <<HELP,
HELP
	},
	{
		'name'		=> 'cell_attr',
		'class'		=> 'Stem::Cell',
		'help'		=> <<HELP,
This value is the attributes for the included Stem::Cell which handles
cloning, async I/O and pipes.
HELP
	},
] ;


sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	return "statements is not an ARRAY ref"
			unless ref $self->{'statements'} eq 'ARRAY' ;

	if ( my $err = $self->db_connect() ) {

		return $err ;
	}

	if ( my $err = $self->prepare() ) {

		return $err ;
	}

	$self->cell_worker_ready() ;

	return $self ;
}

sub db_connect {

	my ( $self ) = @_ ;

	my $db_type = $self->{'db_type'} ;
	my $db_name = $self->{'db_name'} ;
	my $host = $self->{'host'} ;
	my $port = $self->{'port'} ;
	my $user_name = $self->{'user_name'} ;
	my $password = $self->{'password'} ;
	my $extras = $self->{'dsn_extras'} ;

	my $dsn = "dbi:$db_type:$db_name" ;
	$dsn .= ";host=$host" if defined $host ;
	$dsn .= ";port=$port" if defined $port ;
	$dsn .= ";$extras" if defined $extras ;

#print "DSN [$dsn]\n" ;
	my $dbh = DBI->connect( $dsn, $user_name, $password,
				{ 'PrintError' => 0,
				  'FetchHashKeyName' => 'NAME_lc' } )
	    or return DBI->errstr ;

	$self->{'dbh'} = $dbh ;

	return ;
}


sub prepare {

	my ( $self ) = @_ ;

	my %name2statement ;

	my $dbh = $self->{'dbh'} ;

	my $statements = $self->{'statements'} ;

	foreach my $statement ( @{$statements} ) {

	        # Hey, this is ugly.  I guess we need parameter type
	        # coercion ;)
	        $statement = { @{$statement} };
		my $name = $statement->{'name'} ;

		return "statement is missing a name" unless $name ;

		my $sql = $statement->{'sql'} ;

		return "statement '$name' is missing sql" unless defined $sql ;

		$statement->{'return_type'} ||= $self->{'default_return_type'};

		unless ( $self->can( $statement->{'return_type'} ) ) {

			return
		"No such return type for $name: $statement->{'return_type'}";
		}

		my $sth = $dbh->prepare( $sql )
		    or return $dbh->errstr ;

		$statement->{'sth'} = $sth ;

		$name2statement{ $name } = $statement ;
	}

	$self->{'name2statement'} = \%name2statement ;

	return ;
}

sub execute_cmd {

	my( $self, $msg ) = @_ ;

#print "EXEC\n" ;

# why not tell the queue ready before we start this operation. since
# it blocks we will handle that new work until this is done.

	$self->cell_worker_ready() ;

	my $data = $msg->data() ;

	return $self->log_error( "No message data" )
		unless $data ;
	return $self->log_error( "Message data is not a hash " )
		unless ref $data eq 'HASH' ;

	my $sth ;
	my $statement ;

	if ( exists $data->{'sql'} ) {

	    return "Must provide return type" unless exists $data->{'return_type'} ;

		$statement = $data->{'sql'} ;

	    $sth = $self->{'dbh'}->prepare( $statement ) ;

	    return $self->log_error( $self->{'dbh'}->errstr . "\n$statement" )
	    	if $self->{'dbh'}->errstr ;
	}
	else {

	    $statement = $data->{'statement'} ;

	    if ( my $in_cnt = $data->{'in_cnt'} ) {

		    my $sql = $self->{'name2statement'}{$statement}{'sql'} ;

		    my @qmarks = ('?') x $in_cnt ;
		    local( $" ) = ',' ;
		    $sql =~ s/IN\(\)/IN( @qmarks )/i ;  

		    $sth = $self->{'dbh'}->prepare( $sql ) ;

		    return $self->log_error(
				$self->{'dbh'}->errstr . "\n$statement" )
					if $self->{'dbh'}->errstr ;
	    }
	    else {

		    $sth = $self->{'name2statement'}{$statement}{'sth'} ;
		    return $self->log_error(
			    "Unknown statement name: $statement" ) unless $sth ;
	    }
	}


	$self->{'statement'} = $statement ;

	my $bind = $data->{'bind'} || [] ;
	return $self->log_error( "Statement arguments are not a list " )
				 unless ref $bind eq 'ARRAY' ;

	my $dbh = $self->{'dbh'} ;

	my $return_type = $data->{'return_type'} ||
		$self->{'name2statement'}{$statement}{'return_type'} ;

	unless ( $self->can( $return_type ) ) {

		return $self->log_error( 
			"No such return type: $data->{'return_type'}" ) ;
	}

	my $dbi_result = $self->$return_type( $sth, $bind ) ;

	if ( $dbi_result && ! ref $dbi_result ) {

		return( $self->log_error( "[$statement] $dbi_result" ) ) ;
	}

	return $dbi_result ;
}

sub list_of_hashes {

    return shift->_fetch( 'fetchall_arrayref', @_, {} );
}

sub list_of_arrays {

    return shift->_fetch( 'fetchall_arrayref', @_, [] );
}

sub one_hashref {

    return shift->_fetch( 'fetchrow_hashref', @_ );
}

sub column_as_array {

    my( $self, $sth, $bind ) = @_;

    my @column;

    $sth->finish if $sth->{'Active'} ;

    $sth->execute( @{$bind} ) or return $sth->errstr ;

    while ( my @row = $sth->fetchrow_array ) {

	push @column, $row[0];
    }

    return $sth->errstr() if $sth->errstr() ;

    return \@column;
}

sub _fetch {

    my( $self, $method, $sth, $bind, @args ) = @_ ;

    $sth->finish if $sth->{'Active'} ;

    $sth->execute( @{$bind} ) or return $sth->errstr ;

    my $data = $sth->$method( @args ) ;

    return $sth->errstr if $sth->errstr ;

    return $data ;
}

sub rows_affected {

    my( $self, $sth, $bind ) = @_;

    $sth->execute( @{$bind} );

    return $sth->errstr if $sth->errstr ;

    return { 'rows' => $sth->rows };
}

sub insert_id {

    my( $self, $sth, $bind ) = @_;

    my $err = $sth->execute( @{$bind} );

    return $sth->errstr if $sth->errstr ;

#print "ID: [$self->{'dbh'}{'mysql_insertid'}]\n" ;

    return { 'insert_id' => $self->{'dbh'}{'mysql_insertid'} } ;
}

sub log_error {

	my ( $self, $err ) = @_;

	my $log = $self->{'error_log'} ;

	return $err unless $log ;

	Stem::Log::Entry->new (
	       'logs'	=> $log,
	       'level'	=> 5,
	       'label'	=> 'Stem::DBI',
	       'text'	=> "Statement: $self->{'statement'} - $err\n",
	) ;

	return \$err ;
}

1 ;
