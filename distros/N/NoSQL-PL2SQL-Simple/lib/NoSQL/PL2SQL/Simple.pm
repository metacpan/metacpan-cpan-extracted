package NoSQL::PL2SQL::Simple;

use 5.008009;
use strict;
use warnings;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NoSQL::PL2SQL::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	) ] ) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw(
	) ;

our $VERSION = '0.24' ;

use Scalar::Util ;
use base qw( NoSQL::PL2SQL ) ;
use Carp ;

my @autodestroy = () ;

my @sql = (
	[ qw( textkey textvalue 1 ) ],
	[ qw( intkey intvalue 0 ) ],
	[ qw( datekey datevalue 1 ) ],
	) ;
my %sql = map { $_->[0] => $_ } @sql ;

my %private ;

################################################################################
##
##  update() refreshes the instance after data definition changes
##
################################################################################

$private{update} = sub {
	my $self = shift ;
	my $tied = tied %$self ;
	my $package = ref $self ;

	return unless $tied->{tied} ;
	delete $tied->{tied} ;

	my $o = $package->SQLObject( $tied->{dsn}->{object}, 0 ) ;
	my %keys = map { $_ => &{ $private{recno} }( $o, $_ ) } keys %$o ;
	$tied->{keys} = \%keys ;
	} ;


################################################################################
##
##  sqlsave() rolls back the rollback
##
################################################################################

$private{sqlsave} = sub {
	my $self = shift ;
	my $tied = tied %$self ;
	delete $tied->{globals}->{rollback} ;
	} ;


################################################################################
##
##  recno() is part of the constructor.  It uses the internal structure
##  of NoSQL::PL2SQL::Object to pull out the unique recordID.
##
################################################################################

$private{recno} = sub {
	my $self = shift ;
	my $tied = tied %$self ;
	return $tied->record->{objectid} || $tied->{top} unless @_ ;

	my $key = shift ;
	return $tied->data->{$key}->{top} ;
	} ;


################################################################################
##
##  filter() takes two arrays and returns the intersection.  It is called 
##  recursively by query().
##
################################################################################

$private{filter} = sub {
	my @set = @{ shift @_ } ;
	return [] unless @set ;
	return [ sort { $a <=> $b } @set ] unless @_ ;

	my @against = sort { $a <=> $b } @{ shift @_ } ;
	my @out = () ;

	while ( @set && @against ) {
		my $cmp = $set[0] <=> $against[0] ;
		shift @set if $cmp < 0 ;
		shift @against if $cmp > 0 ;
		next if $cmp ;

		push @out, shift @set ;
		shift @against ;
		}

	return \@out ;
	} ;


################################################################################
##
##  index() is the common method to addTextIndex, addNumberIndex, etc.
##
################################################################################

$private{index} = sub {
	my $self = shift ;
	my $tied = tied %$self ;
	my $package = ref $self ;

	$tied->{tied} ||= $package->SQLObject( 
			$tied->{dsn}->{object}, 0 ) ;
	my $i = push @autodestroy, $tied->{tied} ;
	Scalar::Util::weaken( $autodestroy[ $i -1 ] ) ;
	return unless @_ ;

	my $type = shift ;
	map { $self->{$_} = $tied->{tied}->{$_} = $type } @_ ; 
	} ;


################################################################################
##
##  matching() is commonly called by methods to query the index database.
##
################################################################################

$private{matching} = sub {
	my $self = shift ;
	my $tied = tied %$self ;
	my $package = ref $self ;

	my $name = shift ;

	my $format = defined $name?  $sql{ $self->{ $name } }: $sql{intkey} ;

	my @sql = () ;
	push @sql, [ $format->[0], defined $name?
				$tied->{keys}->{ $name }: $tied->{id}
				] ;
	unless ( @_ ) {
		my @rows = $tied->{dsn}->{index}->fetch( @sql ) ;

		return [] unless @rows ;
		return $rows[0] unless ref $rows[0] ;
		return [] unless keys %{ $rows[0] } ;

		my @out = map { $_->{objectid} 
				=> $_->{ $format->[1] } } @rows ;
		return \@out ;
		}

	my $value = shift ;
	push @sql, [ $format->[1], $value, $format->[2] ] ;

	my @rows = $tied->{dsn}->{index}->fetch( @sql ) ;
	return $rows[0] if @rows && ! ref $rows[0] ;
	return [] unless keys %{ $rows[0] } ;

	my @out = map { $_->{objectid} => $_->{ $format->[1] } } @rows ;
	return \@out ;
	} ;


################################################################################
##
##  indexmap() creates the structures to create the SQL insert statements
##  for the index table
##
################################################################################

$private{indexmap} = sub {
	my $self = shift ;
	my $tied = tied %$self ;
	my $keys = shift ;
	my $value = shift ;
	my $orderid = shift ;
	my $format = $sql{ $self->{ $keys->[1] } } ;

	my @index = () ;
	push @index, [ $format->[0], $tied->{keys}->{ $keys->[1] } ] ;
	push @index, [ $format->[1], $value->{ $keys->[0] }, 
			$format->[2] ] ;
	push @index, [ objectid => $orderid ] ;
	return \@index ;
	} ;

################################################################################
##
##  getinstance() returns null for passed instances
##  distinguishes between instances and objects
##
################################################################################

$private{getinstance} = sub {
	my $self = shift ;
	my $tied = tied %$self ;
	return $tied->{parent} ;
	} ;

################################################################################
##
##  A tied hash is used to hide internal properties by overloading access
##  methods.
##
################################################################################

sub TIEHASH {
	my $package = shift ;
	my $self = shift ;
	return bless $self, $package ;
	}

sub CLEAR {
	my $self = shift ;
	undef $self->{clone} ;
	}

sub FETCH {
	my $self = shift ;
	my $key = shift ;
	return $self->{clone}->{$key} ;
	}

sub EXISTS {
	my $self = shift ;
	my $key = shift ;
	return exists $self->{clone}->{$key} ;
	}

sub DELETE {
	my $self = shift ;
	my $key = shift ;
	return delete $self->{clone}->{$key} ;
	}

sub STORE {
	my $self = shift ;
	my $key = shift ;
	my $value = shift ;
	return $self->{clone}->{$key} = $value ;
	}

sub FIRSTKEY {
	my $self = shift ;
	$self->{nextkey} = [ keys %{ $self->{clone} } ] ;
	return $self->NEXTKEY ;
	}

sub NEXTKEY {
	my $self = shift ;
	return shift @{ $self->{nextkey} } ;
	}

sub new {
	return db( @_ ) ;
	}

sub db {
	my $package = shift ;
	my $self = {} ;

	my @dsn = ( @_, $package->dsn ) ;
	carp( "Missing data sources" ) and return undef unless @dsn ;

	my $dsn = {} ;
	$dsn->{object} = shift @dsn ;
	$dsn->{index} = shift @dsn ;

	$package->SQLError( ObjectNotFound => \&newobject ) ;

	my $o = $package->SQLObject( $dsn->{object}, 0 ) ;
	$self->{id} = &{ $private{recno} }( $o ) ;
	$self->{clone} = $o->SQLClone() ;
	$self->{dsn} = $dsn ;
	
	my %keys = map { $_ => &{ $private{recno} }( $o, $_ ) } keys %$o ;
	$self->{keys} = \%keys ;
	tie my %out, __PACKAGE__, $self ;

	return bless \%out, $package ;
	}

sub loadschema {
	my $package = shift @_ unless ref $_[0] ;
	my ( $dsn, $index ) = $package->dsn if defined $package ;

	$dsn ||= shift @_ ;
	my $table = shift @_ if @_ && ! ref $_[0] ;
	$index ||= shift @_ if @_ ;
	$index ||= $dsn->table( $table ) if $dsn && $table ;
	carp( "Missing data sources" ) and return 
			unless defined $dsn && defined $index ;

	$dsn->loadschema ;
	$index->loadschema( $dsn->indexschema ) ;
	}

sub dsn {
	my $package = shift ;
	return () ;
	}

sub addTextIndex {
	my $self = shift ;
	return &{ $private{index} }( $self, $sql[0][0], @_ ) ;
	}

sub addNumberIndex {
	my $self = shift ;
	return &{ $private{index} }( $self, $sql[1][0], @_ ) ;
	}

sub addDateIndex {
	my $self = shift ;
	return &{ $private{index} }( $self, $sql[2][0], @_ ) ;
	}

sub recordID {
	my $array = shift ;
	my @args = @$array ;
	my $self = shift @args ;
	return $args[0] unless wantarray ;
	return @args ;
	}

sub records {
	my $array = shift ;
	my @args = @$array ;
	my $self = shift @args ;

	my @out = map { $self->record( $_ ) } @args ;
	return $out[0] if @out && ! wantarray ;
	return @out ;
	}

sub record {
	my $self = shift ;
	return $self->records if $self->isa('ARRAY') ;

	my $tied = tied %$self ;
	my $package = ref $self ;

	return undef unless @_ ;

	&{ $private{update} }( $self ) ;

	my @args = ( shift @_ ) ;
	push @args, ( @_ && ref $_[0] )? shift @_: undef ;
	my ( $objectid, $value ) = 
			ref $args[0]? ( undef, $args[0] ): @args[0,1] ;

	my $argid = $objectid ;
	my $dsn = $tied->{dsn}->{object} ;
	my $index = $tied->{dsn}->{index} ;
	my $out = {} ;

	if ( ! defined $objectid && $value
			&& ref $value eq ref $self
			&& $value->SQLObjectID ) { 
		$objectid = $value->SQLObjectID ;

		return $self->record( $objectid, $args[1], @_ ) 
				if defined $args[1] ;
		$out = tied %$value ;
		}

	my %index = @_ ;
	my @index = () ;
	if ( $value ) {
		map { push @index, [ $_ => $index{$_} ] }
				grep exists $self->{ $index{$_} }, 
				keys %index ;
		map { push @index, [ $_ => $_ ] }
				grep exists $value->{$_},
				keys %$self ;
		}

	while ( defined $value && defined $objectid ) {
		my $archive = $self->{archive}?
				$package->SQLClone( $dsn, $objectid ):
				undef ;

		$index->delete( [ objectid => $objectid ] ) ;

		if ( $out->{clone} && ! defined $argid ) {
			&{ $private{sqlsave} }( $out->{clone} ) ;
			}
		else {
			delete $out->{clone} ;
			$dsn->delete( [ objectid => $argid ] ) ;
			$out->{clone} = $package->SQLObject( 
					$dsn, $argid, $value
					) ;
			}

		last unless defined $archive ;

		my $archiveid = &{ $private{recno} }(
				$package->SQLObject( $dsn, $archive )
				) ;
		$index->insert( 
				[ intkey => $tied->{keys}->{archive} ],
				[ intvalue => $objectid ],
				[ objectid => $archiveid ]
				) ;

		last ;
		}

	delete $out->{clone} ;
	$out->{clone} = defined $objectid? 
			  $package->SQLObject( $dsn, $objectid ):
			defined $value?
			  $package->SQLObject( $dsn, $value ):
			undef ;

	return undef unless $out->{clone} ;
	$out->{clone}->SQLRollback ;
	$out->{id} = $out->{clone}->sqlobjectid ;	## lc method name
	$out->{parent} = $self ;

	map { $index->update( undef, @$_ ) }
			map { &{ $private{indexmap} }( 
			  $self, $_, $out->{clone}, $out->{id} )
			  } @index ;

	$index->update( undef,
			[ intkey => $tied->{id} ],
			[ intvalue => $out->{id} ],
			[ objectid => $out->{id} ]
			) if $value ;

	tie my %out, __PACKAGE__, $out ;
	return bless \%out, $package ;
	}

sub save {
	my $self = shift ;
	my $tied = tied %$self ;

	return $self->record( @_ ) unless $tied->{parent} ;
	return $tied->{parent}->record( $self, @_ ) ;
	}

sub reindex {
	my $self = shift ;
	my $tied = tied %$self ;
	my $parent = $tied->{parent} ;
	$tied = tied %$parent ;
	my $index = $tied->{dsn}->{index} ;
	my $objectid = $self->SQLObjectID ;

	return "reindex() requires an index name" unless @_ ;
	my $propkey = shift ;
	my $indexkey = @_? shift @_: $propkey ;

	return "unknown index: $indexkey" unless $parent->{ $indexkey } ;

	my $format = $sql{ $parent->{ $indexkey } } ;
	my $key = $tied->{keys}->{ $indexkey } ;

	$index->delete( [ $format->[0] => $key ],
			[ objectid => $objectid ] ) ;
	$index->update( undef, [ $format->[0] => $key ],
			[ $format->[1] => $self->{ $propkey }, $format->[2] ],
			[ objectid => $objectid ] ) ;
	return undef ;
	}

sub SQLObjectID {
	my $self = shift ;
	my $tied = tied %$self ;
	return $tied->{id} ;
	}

sub keyValues {
	my $self = shift ;
	my $indexid = shift ;

	my $instance = &{ $private{getinstance} }( $self ) ;
	carp "Argument is not an object" and return () unless $instance ;

	my $tied = tied %$instance ;
	my $dsn = $tied->{dsn}->{index} ;
	my $format = $sql{ $instance->{$indexid} } ;
	my @sql = ( [ objectid => $self->SQLObjectID ],
			[ $format->[0], $tied->{keys}->{$indexid} ] 
			) ;

	if ( @_ == 0 ) {
		return bless [ $dsn, 
				[ $format->[1], undef, $format->[2] ],
				@sql ], __PACKAGE__ .'::keyValues' 
				unless wantarray ;

		return map { $_->{ $format->[1] } } $dsn->fetch( @sql ) ;
		}

	map { $dsn->insert( @sql, [ $format->[1], $_, $format->[2] ] ) } @_ ;
	}

sub NoSQL::PL2SQL::Simple::keyValues::clear {
	my $args = shift ;
	my $dsn = shift @$args ;

	shift @$args unless @_ ;
	$args->[0]->[1] = shift @_ if @_ ;
	return $dsn->delete( @$args ) ;
	}

sub delete {
	my $self = shift ;
	my $tied = tied %$self ;
	my $package = ref $self ;
	my $recno = shift if @_ ;

	if ( $tied->{parent} ) {
		$recno = $self ;
		$tied = tied %{ $tied->{parent} } ;
		}

	return undef unless $recno ;
	$recno = $recno->SQLObjectID if ref $recno ;

	my @sql = () ;
	push @sql, [ $sql{intkey}->[0], $tied->{id} ] ;
	push @sql, [ $sql{intkey}->[1], $recno ] ;
	$tied->{dsn}->{index}->delete( @sql ) ;
	return $recno ;
	}

sub querytest {
	return &{ $private{matching} }( @_ ) ;
	}

## double check how empty sets are returned
sub query {
	my $self = shift ;
	my $package = ref $self ;

	my @key = () ;
	push @key, [ shift @_ ] if @_ == 1 ;

	my @nvp = () ;
	push @nvp, @key ;
	push @nvp, [ splice @_, 0, 2 ] while @_ ;

	my @error = grep @$_ && ! exists $self->{ $_->[0] }, @nvp ;
	carp sprintf( "Unknown data definition %s", $error[0][0] )
			and return () if @error ;
	my $archive = @nvp && $nvp[0][0] eq 'archive' ;

	my $all = &{ $private{matching} }( $self ) ;
	my $out = @nvp == 0? $all:
			&{ $private{matching} }( $self, @{ shift @nvp } ) ;
	return $out unless ref $out ;

	$all ||= [] ;
	my $save = &{ $private{filter} }( [ keys %{ { @$all } } ] ) ;
	$save = &{ $private{filter} }( 
			$archive? (): ( $save ), 
			[ keys %{ { @$out } } ]
			) if $out != $all ;

	while ( @nvp ) {
		$out = &{ $private{matching} }( $self, @{ pop @nvp } ) || [] ;
		$save = &{ $private{filter} }(
				$save, [ keys %{ { @$out } } ] ) ;
		}

	return wantarray? @$save: 
			bless [ $self, @$save ], $package
			unless @key ;

	my %out = @$out ;
	return map { $_ => $out{$_} } @$save ;
	}

sub DESTROY {}

sub AUTOLOAD {
	my $self = shift ;
	my $package = ref $self ;

	use vars qw( $AUTOLOAD ) ;
	my $func = $AUTOLOAD ;
	$func =~ s/^${package}::// ;
	return exists $self->{$func}? $self->query( $func, @_ ): undef ;
	}

sub newobject {
	my $package = shift ;
	my $error = shift ;
	my $errortext = pop ;

	return carp( $errortext ) && undef if $_[-1] ;
	return $package->SQLObject( @_, {} ) ;
	}

sub END {
	undef @autodestroy ;
	}


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NoSQL::PL2SQL::Simple - Implementation of NoSQL::PL2SQL

=head1 SYNOPSIS

  BEGIN {
	package MyArbitraryClass ;
	use base qw( NoSQL::PL2SQL::Simple ) ;
	}

  use CGI ;

  my $collection = new MyArbitraryClass ;

  ## Writing to and modifying the database
  $collection->save( CGI->new->Vars ) ;
  $collection->delete( CGI->new->Vars->{recordid} ) ;

  ## Accessing the database
  @allemails = values %{ { $collection->contactemail } } ;

  $user = $collection->contactemail('jim@tqis.com')->record ;
  @neighbors = $collection->contactaddress('Ann Arbor')->records ;
  @classmates = $collection->query(
		contactcity => 'Ann Arbor',
		graduationyear => '1989',
		)->records ;


=head1 NoSQL::PL2SQL::Simple VERSUS NoSQL::PL2SQL

NoSQL::PL2SQL performs background persistence for perl objects using SQL and
a relational database:  Persistence is enabled with a simple designation.
Everything else happens automatically in the background.  As a result, 
NoSQL::PL2SQL has practically no defined API.  So it is inadequate for
users who are looking for an alternative to SQL (as in NoSQL).

NoSQL::PL2SQL::Simple solves that problem and provides a complete API to
access stored data.  In effect, these two modules perform a division of labor:
NoSQL::PL2SQL is responsible for storing the data, and NoSQL::PL2SQL::Simple
is responsible for access.

The comparison is also dependent on the data architecture needs.

=over 8

=item Two-Dimensional Tabular Data

Given that RDB's call their data containers I<tables>, the two-dimensional
tabular data structure tends to dominate traditional data architecture.  
While a table is visually easy to comprehend.  A more abstract model extends
a one-dimensional array:  Where, instead of scalars, each array element is 
a set of NVP's (name-value-pairs).  Two-dimensional data is tabular if each 
NVP set shares a common set of names.  Non-tabular two-dimensional data 
is still a tough fit for a conventional RDB.

=item Multi-Dimensional Tabular Data

A multi-dimensional table is best described in terms of a spreadheet, where 
one cell contains a list (or any set).  The description is trickier in
terms of an array of NVP's.  But these data types are getting more and more 
common as CSV data representation starts to give way to XML and JSON.
RDB's can handle complex data by using I<relational tables>.  (the I<R> in 
I<RDB>.)  But RDB data definitions tend to have scaling problem as the data
gets more and complex.

=item Non-Tabular Data

It's possible to cobble together an RDB solution for two-dimensional 
non-tabular data.  But, beyond that, developers are entering a world of pain.
In this realm, NoSQL::PL2SQL provides a clear advantage.

=back

NoSQL::PL2SQL is designed for non-tabular data where traditional RDB's are
not very useful.  NoSQL::PL2SQL::Simple requires some form of tabular data,
and combines the advantages of both NoSQL::PL2SQL and RDB SQL.


=head1 DESCRIPTION

In a traditional RDB, the data structure definition is external, separate
from the content data.  In NoSQL::PL2SQL::Simple, the two exist 
side-by-side.  Both data content and definition have OO representations.  

A data definition can be associated with any arbitrary perl class that 
subclasses NoSQL::PL2SQL::Simple.  In many cases, the subclass is no more
than a name that identifies the definition.  The data definition is 
encapsulated in the class's instantiation or I<instance>.  (I'm using fairly 
precise nomenclature.)  Many of NoSQL::PL2SQL::Simple's methods are called 
via the instance (or collection).

Data content is encapsulated in class I<objects>.  Methods to access or
modify data content are called via these objects.  Both objects and the 
single instance  are blessed into the same class name.  Use appropriate 
variable names to distinguish each in your code.

=head2 Constructor

=head3 new()

According to the wisdom of OO pattern science, the I<constructor> is used
to create the I<instance>.  And a I<factory> (usually applied to the 
instance) is used to create the I<objects>.

=head3 db()

C<new()> no arguments and returns an I<instance> of the data definition class.  As is typical in perl, the method C<NoSQL::PL2SQL::Simple::new()> is the 
conventional constructor.  However, NoSQL::PL2SQL::Simple is invoked by 
creating a subclass, which may need its own constructor.  Consequently, 
the following two statements are equivalent:

  $instance = NoSQL::PL2SQL::Simple->new ;
  $instance = NoSQL::PL2SQL::Simple->db ;

The instance has several functions:

=over 8

=item As a data definition, with methods to alter the definition

=item As a factory, with methods to create objects

=item As a data source, with methods to query the data

=back

All these methods are detailed in the following sections.

=head2 Data Definition Methods

Tabular data is I<tabular> because each element (a data object) has a common
structure. The entire data set can be laid on a grid with identifiable, 
pre-defined column names.  Data elements are laid out as rows which can be 
easily added or deleted.

I use the term I<NVP set> (an associative array in perl) to generalize 
these elements, and the term I<tabular> requires that each NVP set use 
the same names.  It's helpful if the reader can visualize this more abstract
model, because NoSQL::PL2SQL::Simple allows much more flexibility 
(or variation) among each NVP, so the result can be much less tabular than
data stored in a traditional RDB.

The difference is that in NoSQL::PL2SQL::Simple, only some names 
(or columns or fields) need to be commonly defined within each element 
(or object).  These names are determined by the data definition which are 
properties of the instance described above.  

As an example, consider an application that needs to save each user's session 
state.  If the application is complex, with numerous interfaces, this data 
is going to be quite unstructured as the state definition gets more 
complicated.  Nevertheless, there are a handful of common elements, say:
I<SessionID>, I<UserID>, I<Email>, and I<Password>.  Theoretically, this could
be done within a strict tabular structure by marshalling the fuzzy stuff into
a single BLOB value.  (Actually, this approach is not uncommon.)

  ## A simple application for saving a complex session

  BEGIN {
	package TQIS::Session ;
	use base qw( NoSQL::PL2SQL::Simple ) ;
	}
  
  $instance = TQIS::Session->new ;

The data definition is itself an NVP set data object.  This is perl, so it's 
accessed as a hash reference.

  ## display the data definition

  print join "\n", %$instance, '' ;

I<hash reference>, I<associative array>, or I<NVP set> are interchangable
terms.  Each name (or key) in this set is the same name required in each 
data object (or element).  Each associated value is a data type.  The data
types are intrinsic to NoSQ::PL2SQL::Simple, three are currently defined.
There's a little magic under the hood, so the best way to add data 
definitions are the following three methods:

=head3 addTextIndex()

=head3 addNumberIndex()

=head3 addDateIndex()

Here's how it's done in our example:

  $instance->addNumberIndex( qw( UserID ) ) ;
  $instance->addTextIndex( qw( Email Password ) ) ;

In this example I<SessionID> will be an internal, automatically generated key.
Since these definitions do not specify uniqueness, the code to enforce a
unique I<UserID> is shown later in L<Unique Keys>.

=head2 Factory Methods

Generally, an I<instance> needs a data definition before it's available for 
factory methods.

=head3 record()

As described above, the constructor creates an I<instance> that represents 
the data definition.  Data I<objects> are created using a factory method 
applied to the instance.  C<record()> is that factory method.  Because of
this special significance, it is heavily overloaded.

  $session = { ... } ;		## A tabular data object
  $sessionid = 231 ;		## An assigned id I made up

  $object = $instance->record( $session ) ;	## Returns an object copy
  $object = $instance->record( $sessionid ) ;	## Returns the stored object
  $object = $instance->record( 
		$sessionid => $session ) ;	## overwrites a stored object

The same C<record()> factory method is used to read, write, or overwrite a
data object, depending on the arguments.  Naturally, developers can create
conventional C<read()> and C<write()> methods in a subclass.

As a factory, C<record()> is always called via the instance.

=head2 Query Methods

Earlier, I compared NoSQL::PL2SQL::Simple to a solution that marshalls the
non-tabular data into a single BLOB value.  NoSQL::PL2SQL::Simple does
not perform any marshalling, so the resulting data storage is more accessible
and portable.  But it should be obvious that the data marshalled into the 
BLOB is not available for querying or searching.  And this limitation also
applies to NoSQL::PL2SQL::Simple.

Since the query operations are tightly bound to the data definition, it 
follows that the query methods are called on the instance.

=head3 query()

Reading and writing data objects does not require a very complicated API.  
(NoSQL::PL2SQL has practically none).  The power and complexity of 
NoSQL::PL2SQL::Simple lies in its query capabilities.  So this section 
will be more detailed.  Most of the API consists of a single method, 
C<query()>.  Naturally, this method is overloaded, so several variations
are described.

=head3 AUTOLOAD()

Additionally, C<query()> is aliased by C<AUTOLOAD()>.  AUTOLOAD is not 
universally loved perl feature, but it can improve code readability.  

=head3 recordID() ;

Since NoSQL::PL2SQL::Simple doesn't inherently support unique keys, all 
query methods return an array.  C<recordID()> is available when you 
absolutely positively need a single scalar.

  @match = $instance->query( Email => 'jim@tqis.com' ) ;
  @match = $instance->Email('jim@tqis.com') ;		## AUTOLOAD equivalent

  warn "entry not found" unless @match ;
  warn "duplicate entries found" if @match > 1 ;

  $sessionID = $match[0] ;
  ## single scalar requirement
  $sessionID ||= $instance->query( Email => 'jim@tqis.com' )->recordID ;

  $session = $instance->record( $sessionID ) ;

This example demonstrates several concepts:  First, the definition name can be 
used as though it were a method definition, thus omitting the first argument.
Second, C<$sessionID> is an automatically generated unique key that is 
required to use the C<record()> factory method.  NoSQL::PL2SQL::Simple
includes an idiom that is a little cleaner.

  @session = $instance->query( Email => 'jim@tqis.com' )->records ;
  @session = $instance->Email('jim@tqis.com')->records ;	## AUTOLOAD

  warn "entry not found" unless @session ;
  warn "duplicate entries found" if @session > 1 ;

  ## Each of the following statements returns the same value
  $session = $sessions[0] ;
  $session = $instance->query( Email =>'jim@tqis.com' )->record ;
  $session = $instance->Email('jim@tqis.com')->record ;		## AUTOLOAD

C<query() can support more than one qualifier.  This use has no AUTOLOAD 
equivalent.

  @session = $instance->query( 
		Email => 'jim@tqis.com, 
		Password => 'in80gres' )->records ;

  warn "invalid login" unless @session ;
  warn "contact system adminstrator" if @session > 1 ;		## uh-oh

  ## query()'s "and" logic is built in.  
  ## Roll your own "or" logic as follows:

  @results = $instance->query( Email => 'jim@tqis.com' ) ;
  push @results, $instance->query( Password => 'in80gres' ) ;
  %results = map { $_ => 1 } @results ;		## filter duplicates
  @results = keys %results ;

If C<query()> is called with no arguments, the entire data set is returned.
This invocation is typically used to rebuild after changing the data 
definition.

  @keys = $instance->query ;
  @everything = $instance->query->records ; 	## memory intensive

When passed with a single argument, C<query()> behaves similarly, except
each element's key is accompanied by its associated NVP value. 

  %email = $instance->query('Email') ;
  %email = $instance->Email ;			## AUTOLOAD equivalent

  print "select your email address from below\n" ;
  printf "%d\t%s\n", @ea while @ea = each %email ;

  ## an even more ludicrous example:

  %passwords = $instance->query('Password') ;
  @email = $instance->query( Email => CGI->new->Vars->{email} ) ;

  print "select your password from below\n" ;
  map { printf "%s\n", $passwords{$_} } @email ;

These extended query options are designed to access data with minimal 
time and resources. 

=head2 Object Methods

Perl objects data usually do not require accessor methods.  For an 
object consisting of NVP's, data is accessed as follows:

  $value = $object->{name} ;

Developers are expected to subclass NoSQL::PL2SQL::Simple, and so may elect 
to write their own accessors.  

NoSQL::PL2SQL::Simple stores and returns an object identical to what was
originally saved.  But there are hidden properties (taking advantage of
perl's TIE feature) that require accessors, for example C<SQLObjectID>.

=head3 SQLObjectID()

The C<SQLObjectID()> method is inherited from NoSQL::PL2SQL, and returns the
objects unique internal key:

  $sessionID = $object->SQLObjectID ;

=head3 save()

=head3 delete()

These methods are aliases for instance methods:

  $instance->record( $object ) ;
  $object->save ;					## equivalent
  
  $instance->delete( $object ) ;
  $instance->delete( $object->SQLObjectID ) ;		## equivalent
  $object->delete ;					## equivalent

NoSQL::PL2SQL::Simple has many shortcuts, but be careful

  $o = bless {}, ref $instance ;
  $o->save ; 				## This won't work!

  ## This would work
  defined $o->SQLObjectID? $o->save: $instance->save( $o ) ;

  ## But obviously simpler
  $instance->save( $o ) ;

perl's I<bless> feature adds lots of magical capabilities to a reference,
and its I<TIE> feature adds even more.  As shown, the C<SQLObjectID()> 
method returns undefined for untied objects.  But the recommended approach 
is to avoid explicitly calling C<bless()> at all.  NoSQL::PL2SQL always 
simultaneously blesses and ties objects, which avoids the possibility of 
blessed untied objects.

=head3 reindex()

As described, one use of the C<query()> method is to reindex all the 
records, or synchronizing the index table to reflect the data table.  
This process is necessary whenever something is added to the
data definition.  C<reindex()> does not take multiple arguments.

  ## This brute force solution wastes many resources on
  ## pointless reading and writing

  map { $instance->record( $_ )->save } $instance->query ;

  ## This alternative modifies the specific index entry for
  ## each record.
  ## This operation must be repeated for each new data definition

  map { $instance->record( $_ )->reindex('contactemail') } $instance->query ;

=head3 keyValues()

Under the hood, NoSQL::PL2SQL::Simple is primarily NoSQL::PL2SQL with an
indexing subsystem included.  Most of the indexing is transparent.  However,
The C<keyValues()> method is used to manipulate the index directly.  This
method needs to be used to maintain many-to-many data relationships.

Naturally, C<keyValues()> is overloaded, but its use is strightforward.  The
method requires at least one argument, the name (or column or key).

  ## The session object has been redefined to include groups.  
  ## A user may be in several groups.
  ## Start by modifying the data definition

  $instance->addNumberIndex( qw( GroupID ) ) ;

  ## Hypothetically extract a list of groups.  Google App data is 
  ## similarly structured.

  $object = $instance->record( $sessionID ) ;
  @groups = map { $_->{id} } @{ $object->{Groups} } ;
  $object->keyValues( GroupID => @groups ) ;

  print "List of Groups:\n" ;
  print join "\n", $object->keyValues('GroupID'), '' ;

In this particular example, state data will be constantly updated.  
Unfortunately, C<keyValues()> always needs to be explicitly called.  So
all of the following code is now required to save session data:

  $sessiondata = ... ; 	## unblessed, untied raw data
  $object = $instance->save( $sessionID, $sessiondata ) ;
  @groups = map { $_->{id} } @{ $object->{Groups} } ;
  $object->keyValues('GroupID')->clear ;
  $object->keyValues( GroupID => @groups ) ;

Relationships defined by the C<keyValues()> method are intended to be
persistent.  See the discussion under L<CAVEATS>.

=head3 clear()

The C<clear()> method is indirectly applied to a NoSQL::PL2SQL::Simple
object as follows:

  @groups = $object->keyValues('GroupID') ;
  $object->keyValues('GroupID')->clear ;		## Deletes all keys
  $object->keyValues('GroupID')->clear( $groups[0] ) ;	## Selective

=head1 DATA SOURCE CLASSES

NoSQL::PL2SQL uses a single table to store arbitrarily structured data.  
There is no need to create different tables for different types of objects.
Although NoSQL::PL2SQL::Simple requires a pair of tables, the data structure 
definition is independent of these tables, so one pair of tables can be used 
for numerous implementations.  In fact, a completely normalized database 
can be built without using separate tables.

For simplicity, the previous examples had no code that defines the
data source.  To keep things simple, subclass NoSQL::PL2SQL::Simple
in a separate I<Data Source Class> and define the data source there.

  package TQIS::PL2SQL::MyData ;		## An arbitrary class name
  use base qw( NoSQL::PL2SQL::Simple ) ;	## Do not change this line

  use NoSQL::PL2SQL::DBI::SQLite ;		## Use one of the available
						## drivers.

  my @dsn = () ;				## Do not change this line

  ## data source subclasses override this dsn() method
  sub dsn {
	return @dsn if @dsn ;			## Do not change this line

	my %tables ;
	$tables{objectdata} = 'aTableName' ;	## Personal preference
	$tables{querydata} = 'anotherTableName' ;	## Ditto

	push @dsn, new NoSQL::PL2SQL::DBI::SQLite $tables{objectdata} ;
	$dsn[0]->connect( 'dbi:SQLite:dbname=:memory:', '', '') ;

	push @dsn, $dsn[0]->table( $tables{querydata} ) ;
	return @dsn ;				## Do not change this line
	}

  ## Each of the following classes can have independent data structure
  ## definitions.  After data definition, the classes below can be used
  ## without additional code.

  package MyArbitraryClass ;
  use base qw( TQIS::PL2SQL::MyData ) ;

  package TQIS::HighSchools ;
  use base qw( TQIS::PL2SQL::MyData ) ;

  package TQIS::HighSchoolFriends ;
  use base qw( TQIS::PL2SQL::MyData ) ;

  package TQIS::GPRC::Members ;
  use base qw( TQIS::PL2SQL::MyData ) ;

This sample code can be written into a single file and installed in perl's 
class path.  However, before proceeding, make sure to run the following 
installation code:

  use TQIS::PL2SQL::MyData ;

  TQIS::PL2SQL::MyData->loadschema ;


=head1 OTHER FEATURES

=head2 Index Mapping

In its earliest incarnations, this module was used to store form data 
submitted from website forms.  At one time, these forms were created by 
Adobe DreamWeaver, where the form fields were renamed everytime the form 
was updated.  The resulting hack remains, and is described here as
I<Index Mapping>.

A more hypothetical situation is that the data is updated by users who 
submit a spreadsheet.  Upon submission, each spreadsheet row is added as
a new record, using the definition in the column headers.  After some
successful period of production, suddenly one of the column names is
changed from I<Email> to I<ContactEmail>.

  ## First solution:  Change the code
  ## Find all occurences of "save()" or "record()" equivalents, and 
  ## change as follows:

  $instance->record( CGI->new->Vars, ContactEmail => 'Email' ) ;
  $instance->save( CGI->new->Vars, ContactEmail => 'Email' ) ;

  ## Alternate solution:  Change the data definition
  $instance->addTextIndex( qw( ContactEmail ) ) ;
  map { $instance->record( $_ )->reindex( Email => ContactEmail )
			$instance->query ;

The second solution is probably more maintainable, except that the data 
definition has become cluttered.  The ultimate fix requires some 
understanding of the NoSQL::PL2SQL innards, but it looks like this:

  my $datadef = NoSQL::PL2SQL::SQLObject( 
		ref( $instance ),
		$instance->dsn->[0], 0 ) ;
  delete $datadef->{Email} ;
  undef $datadef ;

I<Index Mapping> is also useful for a similar problem.  EG., in a contact
manager, the input data may specify a I<Work Email>, I<Home Email>, 
and I<Other Email>.  When a user is queried by email, it shouldn't matter 
where that address was originally entered.  The answer is similar to the 
I<First Solution> in the previous example.

  $instance->addTextIndex( qw( Email ) ) ; 	## Ideally during installation

  $instance->save( CGI->new->Vars,
		'Work Email' => 'Email',
		'Home Email' => 'Email', 
		'Other Email' => 'Email'
		) ;

=head2 Archiving Records

NoSQL::PL2SQL has a feature called incremental updates:  Whenever an object
is modified, only the modifications are written to the data source.  
NoSQL::PL2SQL::Simple will occassionally take advantage of this feature:

  $object->save ;			## Incremental write
  $object->save( $newobject );		## Full rewrite

On a full rewrite, the old data is deleted and the replacement is written 
as new data.  In this case, it's slightly faster to avoid deleting the
old data if data storage isn't an issue.  NoSQL::PL2SQL::Simple allows
this operation, and acts like a time machine that archives each version of 
stored data for all write operations.

This feature is enabled by adding an element named I<archive> to the data
definition:

  $instance->addNumberIndex( qw( archive ) ) ;	## on installation

  @history = $instance->archive( $sessionID )->records ;	## at runtime

Ultimately, the I<archive> feature isn't quite so efficient because additional
write operations are performed to insure that the C<$sessionID> value remains
constant.


=head1 IMPLEMENTATION EXAMPLES

Most of this section is still under construction.  


=head2 Unique Keys

The example at the beginning of this document discussed an application that
uses NoSQL::PL2SQL::Simple to save state data.  This application relies on
an externally supplied UserID that must be unique.  This code ensures
that uniqueness.

  $instance = TQIS::Session->new ;
  $sessiondata = ... ; 	## unblessed, untied raw data

  @args = $sessionID? ( $sessionID ):
		$instance->UserID( $sessiondata->{UserID} ) ;
  $instance->save( @args, $sessiondata ) ;

=head1 CAVEATS

=head2 keyValues()

When a record is saved, its indexes are all rebuilt.  This implementation
deletes all the index records associated with the record, and then 
automatically inserts new records to reflect replacement values.  So the
C<keyValues()> operation must be manually repeated upon every save, as 
shown in the code below.

  $sessiondata = ... ; 	## unblessed, untied raw data
  $object = $instance->save( $sessionID, $sessiondata ) ;
  @groups = map { $_->{id} } @{ $object->{Groups} } ;
  $object->keyValues('GroupID')->clear ;	## currently unnecessary
  $object->keyValues( GroupID => @groups ) ;

This example works fine, because the elements in C<@groups> are 
readily accessible.  In practice, if users select their own groups, the 
group relationships should always be defined within C<$sessiondata>.  
However, if other external operations also define the group-user 
relationships, that data needs to be more persistent.

The C<keyValues()> method is extended so that the following workaround is
available:

  $sessiondata = ... ; 	## unblessed, untied raw data
  @groups = $instance->record( $sessionID )->keyValues('GroupID') ;
  ## potential race condition occurs here
  $object = $instance->save( $sessionID, $sessiondata ) ;
  $object->keyValues( GroupID => @groups ) ;

The problem with this approach is a potential race condition if other
users insert new group relationships during this operation.

Ultimately, the solution is to flag index records that are manually 
defined to guarantee their persistence.  This feature is not 
particularly complicated, but requires a change to the underlying
data structure.  Because the effort involves NoSQL::PL2SQL::DBI and 
worrying about backward compatibility, the change is planned for the next 
major release.

=head1 EXPORT 

None by default.

=head1 SEE ALSO

=over 8

=item NoSQL::PL2SQL

=item NoSQL::PL2SQL::DBI

=item http://pl2sql.tqis.com/

=back

=head1 AUTHOR

Jim Schueler, E<lt>jim@tqis.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 Jim Schueler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
