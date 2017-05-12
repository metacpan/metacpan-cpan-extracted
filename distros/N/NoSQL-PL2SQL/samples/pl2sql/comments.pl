package pl2sql::comments ;
use base qw( NoSQL::PL2SQL ) ;
use NoSQL::PL2SQL::DBI::MySQL ;
use htmlparse ;
use mysql ;


###########################################################################
##
##  Define data sources:
##
##  $dsn{comments} is used to generate objectid's and map top level 
##  page records.
##
##  $dsn{objects} is the PL2SQL repository.
##
###########################################################################

$dsn{comments} = NoSQL::PL2SQL::DBI::MySQL->new( 'pl2sql_comments' )->mysql ;
$dsn{objects} = NoSQL::PL2SQL::DBI::MySQL->new( 'pl2sql_objectdata' )->mysql ;


###########################################################################
##
##  The constructor is used to retrieve existing comment objects and
##  create new ones.
##
###########################################################################

sub new {
	my $package = shift ;
	my $arg = shift ;
	my $self = $package->SQLObject( $dsn{objects}, $arg ) ;

	return $self unless ref $arg ;

	$self->{objectid} = $self->SQLObjectID ;

	if ( $self->{parent} ) {
		my $parent = $package->SQLObject( 
				$dsn{objects}, $self->{parent} ) ;
		push @{ $parent->{kids} }, $self->{objectid} ;
		}
	else {
		$dsn{comments}->insert( 
				[ objectid => $self->{objectid} ],
				[ docid => $self->{docid} ]
				) ;
		}

	return $self ;
	}


###########################################################################
##
##  The bydocument function takes a single argument that identifies an HTML
##  document (page) and returns all the top level records.  
##
##  objectid is assigned automatically.  The ORDER BY clause is intended
##  to return the records in chronological order, and is probably 
##  unnecessary.  
##
###########################################################################

sub bydocument {
	shift @_ if $_[0] eq __PACKAGE__ ;
	my $docid = shift ;

	return grep ! $_->{deleted},
			map { __PACKAGE__->new( $_ ) } 
			reverse map { $_->[0] } 
			$dsn{comments}->rows_array( 'SELECT objectid FROM %s'
			  ." WHERE docid=$docid ORDER BY objectid"
			) ;
	}


###########################################################################
##
##  kidcount() is a method to display a count of replies.  This method 
##  needs to be replaced with something more accurate, because in this 
##  design, deleted records are still reflected in the results.
##
###########################################################################

sub kidcount {
	my $self = shift ;
	return scalar @{ $self->{kids} || [] } ;
	}


###########################################################################
##
##  htmltext() method parses text data and cleans any potentially 
##  malicious HTML code.
##
###########################################################################

my %tags = map { $_ => 1 } 
		map { $_, "/$_" } qw( a b i p br code li ol ul ) ;

sub htmltext {
	my $self = shift ;
	my $fid = shift ;		## field name
	my $p = new htmlparse $self->{ $fid } ;

	return join '', map { $_->{textvalue} } @{ $p->{tags} }
			unless $fid eq 'comment' ;

	return join '', map { ( $tags{ $_->{tagtype} }? 
			  '<'.$_->{tagvalue}.'>': '' ), 
			  $_->{textvalue} 
			} @{ $p->{tags} } ;
	}

1
