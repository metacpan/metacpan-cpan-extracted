package NoSQL::PL2SQL;

use 5.008009;
use strict;
use warnings;

use Scalar::Util ;
use Carp ;
use NoSQL::PL2SQL::Node ;
use NoSQL::PL2SQL::Object ;
use NoSQL::PL2SQL::Perldata ;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NoSQL::PL2SQL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] ) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw() ;

our $VERSION = '1.21';

require XSLoader;
XSLoader::load('NoSQL::PL2SQL', $VERSION);

# Preloaded methods go here.

our @members = qw( perldata sqltable globals ) ;
my @errors = qw( 
		BlessedCaller InvalidDataSource 
		InvalidObjectID UnconnectedDataSource
		DuplicateObject ObjectNotFound CorruptData 
		TableLockFailure
		) ;
my %errors = () ;

sub SQLError {
	return sqlerror( @_ ) ;
	}

sub sqlerror {
	my $package = shift ;
	my @nvp = () ;
	push @nvp, [ splice @_, 0, 2 ] while @_ ;
	
	foreach my $a ( @nvp ) { 
		my $k = join '::', $package, $a->[0] ;
		$errors{ $k } = $a->[1] ;
		}
	
	return @errors if wantarray ;
	return [ keys %errors ] ;
	}

sub SQLCarp {
	return sqlcarp( @_ ) ;
	}

sub sqlcarp {
	my $package = shift ;
	my $key = shift ;
	my $error = shift ;
	$error->{Error} = $key ;
	
	my $k = join '::', $package, $key ;
	return &{ $errors{$k} }( $package, $error, @_ )
			if exists $errors{$k} && ref $errors{$k} eq 'CODE' ;
	carp( $_[-1] ) ;
	return undef ;
	}

sub SQLObjectID {
	return sqlobjectid( @_ ) ;
	}

sub sqlobjectid {
	my $self = shift ;
	my $tied = NoSQL::PL2SQL::Object::item( $self )->[1] ;
	return $tied unless defined $tied ;
	return $tied->record->{objectid} ;
	}

sub SQLObject {
	return sqlobject( @_ ) ;
	}

sub sqlobject {
	my $package = shift ;
	my @args = @_ ;
	my $dsn = shift ;
	my $objectid = @_ && ! ref $_[0]? shift( @_ ): undef ;
	my $object = @_ && ref $_[0]? shift( @_ ): undef ;

	return sqlcarp( $package, $errors[0], {}, @args, 
			'SQLObject must be called as a static method.' ) 
			if ref $package ;
	return sqlcarp( $package, $errors[1], {}, @args, 
			'Missing or invalid data source.' ) 
			unless eval { $dsn->db } ;
	return sqlcarp( $package, $errors[2], {}, @args, 
			'Fetch requires an objectid.' ) or return undef
			unless defined $objectid || defined $object ;
	return sqlcarp( $package, $errors[3], {}, @args, 
			'SQLObject requires a connected database.' 
		  	  .'Use NoSQL::PL2SQL::Node::factory for testing.' )
			unless $dsn->dbconnected ;

	if ( defined $objectid && defined $object ) {
		my $perldata = $dsn->fetch( [ objectid => $objectid, 0 ],
				[ objecttype => $package, 1 ] ) ;
		return sqlcarp( $package, $errors[4], 
				  { $errors[4] => $perldata },
				  @args, "Duplicate object $objectid." )
				if scalar values %$perldata ;
		}

	## write to database
	$objectid = NoSQL::PL2SQL::Node->factory( $dsn, $objectid, 
			bless( $object, $package ), $package )
			if defined $object ;

 	my $self = bless { sqltable => $dsn }, 'NoSQL::PL2SQL::Clone' ;
	$self->{perldata} = $dsn->fetch( [ objectid => $objectid ],
			  [ objecttype => $package, 1 ] ) ;
	return sqlcarp( $package, $errors[5], {}, @args, 
			"Object not found for object $objectid." )
			unless scalar values %{ $self->{perldata} } ;

 	my $perlnode = $self->record( $objectid ) || { id => 0 } ;
	( $perlnode ) = grep $_->{reftype} eq 'perldata',
			  values %{ $self->{perldata} }
			unless exists $self->{perldata}->{$objectid}
			  && $self->{perldata}->{$objectid}->{reftype}
			  eq 'perldata' ;
			  
	return sqlcarp( $package, $errors[6], { $errors[6] => $self }, @args,
			'Missing perldata node- possible data corruption.' )
			unless $perlnode->{id} ;

	$self->{top} = $self->record( $perlnode->{id} )->{refto} ;
	$self->{package} = $package ;
	$self->{reftype} = $self->record->{reftype} ;
	$self->{globals} = { memory => {}, 
			scalarrefs => {},
			top => $self->{top},
			header => $perlnode,
			} ;
	$self->{globals}->{clone} = $self ;

	if ( $self->{reftype} eq 'hashref' ) {
		tie my( %out ), $self ;
		return $self->memorymap( $self->mybless( \%out ) ) ;
		}
	elsif ( $self->{reftype} eq 'arrayref' ) {
		tie my( @out ), $self ;
		return $self->memorymap( $self->mybless( \@out ) ) ;
		}
	elsif ( $self->{reftype} eq 'scalarref' ) {
		$self->loadscalarref( $self->{top} ) ;
		tie my( $out ), $self ;
		return $self->memorymap( $self->mybless( \$out ) ) ;
		}
	else {
		return $self->sqlclone ;
		}
	}

sub SQLClone {
	return sqlclone( @_ ) ;
	}

sub sqlclone {
	my $tied = shift ;
	$tied = $tied->sqlobject( @_ ) if @_ >= 2 ;

	my $self = NoSQL::PL2SQL::Object::item( $tied )->[1] ;
	return $tied unless defined $self ;
	return $self->sqlclone ;
	}

sub SQLRollback {
	return sqlrollback( @_ ) ;
	}

sub sqlrollback {
	my $self = shift ;
	my $tied = NoSQL::PL2SQL::Object::item( $self )->[1] ;
	return $tied unless defined $tied ;
	$tied->{globals}->{rollback} = 1 ;
	}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NoSQL::PL2SQL - Relational Database Persistence for Perl Objects

=head1 SYNOPSIS

NoSQL::PL2SQL is intended for class designers.  An example of a class that implements NoSQL::PL2SQL, MyArbitraryClass, is defined below.

  package MyArbitraryClass ;
  use base qw( NoSQL::PL2SQL ) ;

  ## define a data source
  use NoSQL::PL2SQL::DBI::SQLite ;
  my $tablename = 'objectdata' ;
  my $dsn = new NoSQL::PL2SQL::DBI::SQLite $tablename ;
  $dsn->connect( 'dbi:SQLite:dbname=:memory:', '', '') ;

  # Preloaded methods go here.

  sub new {
	my $package = shift ;
	my $object = @_? shift( @_ ): {} ;
	my $self = $package->SQLObject( $dsn, $object ) ;
	printf "userid: %d\n", $self->SQLObjectID if ref $object ;
	return $self ;
	}  

  sub error {
	my $self = shift ;
	$self->SQLRollback ;
	warn "unrecoverable error" ;
	}

  sub clone {
	my $self = shift ;
	return $self->SQLClone ;
	}

  ## Should not be necessary
  END {
	## Destroy all instantiations
	}

The main requirement is that the class inherit NoSQL::PL2SQL methods.  Second, a data source needs to be defined.  One of NoSQL::PL2SQL's features is a "universal" data structure that can accomodate heterogenous, complex data structures.  As a result the table that defines the data source can be shared among different classes.

NoSQL::PL2SQL::DBI contains access methods used by NoSQL::PL2SQL.  In addition to the shown constructor and connector, C<< $dsn->loadschema >> is used to build the datasource table when an application is installed.

NoSQL::PL2SQL's interface is intended to be built into an implementing class's constructor, generally in place of the C<bless> statement.  In this example, the C<< AnyArbitraryClass->new() >> constructor can be invoked three ways.  First, with no arguments, the constructor returns an empty persistent blessed hash reference.  Second, if the single argument is a hash reference, the constructor converts the structure into a persistent blessed object.  Third, if the argument is valid, numeric ObjectID, the constructor returns the stored object that exactly matches the state when it was previously destroyed.

In this example, when a persistent object is initialized, its ObjectID is printed out.  Naturally, this is a clumsy way to maintain object references, although personally, I am not above hardcoding a reference into an HTML document.

Another option is to use a fixed object as an index to other objects.  Unfortunately, as of this writing, NoSQL::PL2SQL has no features for object locking, and this strategy would quickly foul up in a multi-user environment.  A third option is to define another data source to map the ObjectID to another key, such as a user's email address.  A fourth, more complicated example is shown below.

Objects are automatically written when they are destroyed.  This feature can be disabled by calling C<SQLRollback()>.  Another solution is to create an untied cloned object, using C<SQLClone()>.  Modifications to the clone are destroyed along with the object.

Results have been erratic and unsatisfactory when object destruction is postponed until global destruction- although experienced programmers will always scope the objects they use.  If a particularly robust solution is required, maintain a univeral list of all instantiations and explicitly destroy each one using an C<END{}> clause, as shown.

=head1 DESCRIPTION

Apparently, many programmers, when envisioning a new project, think about database schemas and imagine the SQL statements that join everything together.  Well into the design, they implement a thin object, using one of the numerous solutions available, to create an OO interface for their application.

I say "apparently" and "many" because I am not among them.  When I envision a new project, I think about classes, interfaces, and imagine lines of inheritance.  Well into the prototype, I am still using native marshalling mechanisms, and when the time comes to add robust and portable persistence, I consider the database design a nuisance.

There are fewer tools for programmers like me-  Although some of the NoSQL initiatives are starting to attract attention.  This design started with some specific objectives to meet my needs, and a few additional features added along the way.

=over 8

=item 1.  Most importantly, the interface needs to be simple and unobtrusive.

=item 2.  The data implementation needs to be flexible and portable- intended to be rolled out on any shared server that provides MySQL.

=item 3.  The implementation should be relatively lightweight, fast, and minimize resources.

=back

The interface is intended to be a drop-in replacement for Perl's bless operator.  The C<SQLObject()> method returns a blessed object that is automatically tied to NoSQL::PL2SQL's RDB persistance.

=head1 ERROR HANDLING

If you're comfortable writing closures or anonymous subroutines, V1.03 uses error handlers.  An application or implementing class can now resolve problems during run-time.  Most errors are thrown for the C<SQLObject()> method- although C<SQLClone()> can be invoked as an alias for C<SQLObject()>.  The following errors are defined, the triggering method is shown in parentheses.

=head3 BlessedCaller (SQLObject)

C<SQLObject()> should be called as a constructor.  Its first argument must be a classname string.  Otherwise, this error is thrown.  C<SQLClone()> is intended to be called as an object method.

=head3 InvalidDataSource (SQLObject)

If the first argument does not instantiate C<NoSQL::PL2SQL::DBI>, this error is thrown.

=head3 InvalidObjectID (SQLObject)

If the first argument is valid, this error is thrown if the second argument is missing.

=head3 UnconnectedDataSource (SQLObject)

The data source must be connected using the C<DBI::Connect()> method or this error is thrown.

=head3 DuplicateObject (SQLObject)

If thrown with 3 valid arguments, C<SQLObject()> will try to assign the second argument as an ObjectID.  If that ObjectID has already been assigned, this error is thrown.

=head3 ObjectNotFound (SQLObject) 

If the second argument is a scalar it is understood to be an ObjectID.  C<SQLObject()> will either retrieve the mapped object or throw this error.

=head3 CorruptData (SQLObject)

An ObjectID assigned by C<SQLObject()> matches the record number of the node tree header.  The header record is identified where reftype == 'perldata'.  Otherwise, this error is thrown.

=head3 TableLockFailure (DESTROY)

As of V1.2, PL2SQL attempts a lock operation on the table before writing updates.  Instead of blocking indefinitely, the lock attempt fails after 10 seconds.  This handler should be overridden to safely dump updates and notify an administrator.

By default, C<SQLObject()> errors carp an English text message and return undefined.  A custom error handler could translate the message, return a custom error value, or recurse with different arguments.  Since C<SQLObject()> always returns a non-scalar on success, any scalar can be used to identify an error.

To assign a handler, use the following format:

  ## $function is an anonymous function or closure
  my $function = sub {
	my $package = shift ;	## First argument to SQLObject
	my $errorid = shift ;	## One of the error keys listed above
	my $errorobj = shift ;	## A hash reference containing useful state
				## data.  Usually keyed on $errorid
	my $textmessage = pop ;	## The default English error message
	my @args = @_ ;		## The remaining arguments passed to SQLObject

	## Handler code goes here
	} ;

  my @keys = SQLError( $key => $function ) ;
  ## $key is one of the keys listed above

For convenience, C<SQLError()> returns a list of all the active error keys.


=head1  AN EXAMPLE USING A STRING KEY

As part of the design objectives, my applications need to be able to migrate their data to NoSQL::PL2SQL.  Primarily, I need to specify the object ids that key each object.  (Did I mention these are hardcoded in my HTML?)  In order to specify an object id, see the example below.

When specifying object ids, care should be taken to ensure that each id is unique.  For that reason, an application should either consistently assign ids or always use automatic assignments.  For practicality, this uniqueness constraint only applies to objects in a given class.  In other words, the key definition is a combination of the class name and object id.  Since the class name is a string, the schema can be manipulated to use string keys instead of numerics.  The MyArbitraryClass is redefined below to illustrate this approach.

  ## SQLObject creation using a specified object id
  # MyArbitraryClass->SQLObject( $dsn, $objectid => $dataobject ) ;

  package MyArbitraryClass ;
  use base qw( NoSQL::PL2SQL ) ;

  sub new {
	my $package = shift ;

	return warn unless @_ ;
	my $object = shift @_ ;	## a user record or email scalar

	my $self = ref $object? 
			NoSQL::PL2SQL::SQLObject( 
			  $object->{email}, $dsn, 0, $object ):
			NoSQL::PL2SQL::SQLObject( $object, $dsn, 0 ) ;
	return bless $self, $package ;
	}  

The constructor is called with a single argument that is either the email address as scalar string, or a user record where the email address is an element called "email".  With this approach, the email address masquerades as a class name.  The object id is not accessible to the user, so it should consistently be set to a value such as 0.  Using this strategy, a user record is accessed whenever a user enters an email address.


=head1 ARCHITECTURE

XML::Dumper::pl2xml provides the basic mechanism for converting an arbitrary complex Perl data structure into an XML tree.  XML::Parser::Nodes treats this tree as a set of identical nodes.  Originally, NoSQL::PL2SQL::Node simply extended this module by adding a method to write itself as a RDB table record.  The name PL2SQL is a reference to this legacy.

Hopefully, users will infer PL2SQL also includes SQL2PL functionality, so implementing objects can move back and forth between persistent storage and active use.  The approach is to retain the node tree structure, and use Perl TIE magic to make the node containers appear as the original object members.  The SQL2PL functionality is embodied in the NoSQL::PL2SQL::Object package, which defines the TIE constructors and all overloading methods.

NoSQL::PL2SQL::DBI defines a data abstraction for accessing the data sources.  The raw RDB record data is accessed using methods in the NoSQL::PL2SQL::Perldata package.  Each of the modules contains detailed information about their architecture and internal operations.


=head2 EXPORT

None by default.



=head1 SEE ALSO

=over 8

=item XML::Parser::Nodes

=item NoSQL::PL2SQL::DBI

=item http://pl2sql.tqis.com/

=back

=head1 AUTHOR

Jim Schueler, E<lt>jim@tqis.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jim Schueler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.
=cut
