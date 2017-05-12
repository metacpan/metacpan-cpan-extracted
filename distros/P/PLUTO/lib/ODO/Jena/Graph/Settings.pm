package ODO::Jena::Graph::PSet;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;

use ODO::RDFS::Class;
@ISA = ( 'ODO::RDFS::Class', );

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;

#
# Description: 
#
# Schema URI: http://jena.hpl.hp.com/2003/04/DB#
#
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName('ODO::Jena::Graph::PSet::PropertiesContainer');
	$self->properties( bless {},
					   'ODO::Jena::Graph::PSet::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	if ( exists( $properties{'PSetName'} )
		 && defined( $properties{'PSetName'} ) )
	{

		unless (
				 UNIVERSAL::isa(
								 $properties{'PSetName'},
								 'ODO::Jena::Graph::Properties::PSetName'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('PSetName') ) {
			return undef;
		}
		$self->properties()->PSetName( $properties{'PSetName'} );
	}
	if ( exists( $properties{'PSetTable'} )
		 && defined( $properties{'PSetTable'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'PSetTable'},
								 'ODO::Jena::Graph::Properties::PSetTable'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('PSetTable') ) {
			return undef;
		}
		$self->properties()->PSetTable( $properties{'PSetTable'} );
	}
	if ( exists( $properties{'PSetType'} )
		 && defined( $properties{'PSetType'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'PSetType'},
								 'ODO::Jena::Graph::Properties::PSetType'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('PSetType') ) {
			return undef;
		}
		$self->properties()->PSetType( $properties{'PSetType'} );
	}
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#PSet>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#PSet';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = (
					   ''          => '',
					   'PSetName'  => 'ODO::Jena::Graph::Properties::PSetName',
					   'PSetTable' => 'ODO::Jena::Graph::Properties::PSetTable',
					   'PSetType'  => 'ODO::Jena::Graph::Properties::PSetType',
	);
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::PSet::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Class::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Class::PropertiesContainer', );

# Methods
sub PSetName {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::PSetName' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						  ODO::Jena::Graph::Properties::PSetName->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
									  'ODO::Jena::Graph::Properties::PSetName');
}

sub PSetTable {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::PSetTable' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						 ODO::Jena::Graph::Properties::PSetTable->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
									 'ODO::Jena::Graph::Properties::PSetTable');
}

sub PSetType {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::PSetType' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						  ODO::Jena::Graph::Properties::PSetType->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
									  'ODO::Jena::Graph::Properties::PSetType');
}
1;


package ODO::Jena::Graph::Settings;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Class;
@ISA = ( 'ODO::RDFS::Class', );

#
# Description: #
# Schema URI: http://ibm-slrp.sourceforge.net/uris/odo/2007/01/jena-graph-schema##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
							 'ODO::Jena::Graph::Settings::PropertiesContainer');
	$self->properties( bless {},
					   'ODO::Jena::Graph::Settings::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	if ( exists( $properties{'GraphLSet'} )
		 && defined( $properties{'GraphLSet'} ) )
	{

		unless (
				 UNIVERSAL::isa(
								 $properties{'GraphLSet'},
								 'ODO::Jena::Graph::Properties::GraphLSet'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('GraphLSet') ) {
			return undef;
		}
		$self->properties()->GraphLSet( $properties{'GraphLSet'} );
	}
	if ( exists( $properties{'GraphName'} )
		 && defined( $properties{'GraphName'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'GraphName'},
								 'ODO::Jena::Graph::Properties::GraphName'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('GraphName') ) {
			return undef;
		}
		$self->properties()->GraphName( $properties{'GraphName'} );
	}
	if ( exists( $properties{'GraphType'} )
		 && defined( $properties{'GraphType'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'GraphType'},
								 'ODO::Jena::Graph::Properties::GraphType'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('GraphType') ) {
			return undef;
		}
		$self->properties()->GraphType( $properties{'GraphType'} );
	}
	if ( exists( $properties{'GraphId'} )
		 && defined( $properties{'GraphId'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'GraphId'},
								 'ODO::Jena::Graph::Properties::GraphId'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('GraphId') ) {
			return undef;
		}
		$self->properties()->GraphId( $properties{'GraphId'} );
	}
	if ( exists( $properties{'GraphPrefix'} )
		 && defined( $properties{'GraphPrefix'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'GraphPrefix'},
								 'ODO::Jena::Graph::Properties::GraphPrefix'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('GraphPrefix') ) {
			return undef;
		}
		$self->properties()->GraphPrefix( $properties{'GraphPrefix'} );
	}
	return $self;
}

sub queryString {
	return
'(?subj, rdf:type, <http://ibm-slrp.sourceforge.net/uris/odo/2007/01/jena-graph-schema#Settings>)';
}

sub objectURI {
	return
'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/jena-graph-schema#Settings';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = (
				   ''            => '',
				   'GraphLSet'   => 'ODO::Jena::Graph::Properties::GraphLSet',
				   'GraphName'   => 'ODO::Jena::Graph::Properties::GraphName',
				   'GraphType'   => 'ODO::Jena::Graph::Properties::GraphType',
				   'GraphId'     => 'ODO::Jena::Graph::Properties::GraphId',
				   'GraphPrefix' => 'ODO::Jena::Graph::Properties::GraphPrefix',
	);
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Settings::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Class::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Class::PropertiesContainer', );

# Methods
sub GraphLSet {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::GraphLSet' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						 ODO::Jena::Graph::Properties::GraphLSet->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
									 'ODO::Jena::Graph::Properties::GraphLSet');
}

sub GraphName {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::GraphName' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						 ODO::Jena::Graph::Properties::GraphName->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
									 'ODO::Jena::Graph::Properties::GraphName');
}

sub GraphType {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::GraphType' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						 ODO::Jena::Graph::Properties::GraphType->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
									 'ODO::Jena::Graph::Properties::GraphType');
}

sub GraphId {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::GraphId' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						   ODO::Jena::Graph::Properties::GraphId->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
									   'ODO::Jena::Graph::Properties::GraphId');
}

sub GraphPrefix {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::GraphPrefix' )
	  )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
					   ODO::Jena::Graph::Properties::GraphPrefix->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
								   'ODO::Jena::Graph::Properties::GraphPrefix');
}
1;


package ODO::Jena::Graph::LSet;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Class;
@ISA = ( 'ODO::RDFS::Class', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName('ODO::Jena::Graph::LSet::PropertiesContainer');
	$self->properties( bless {},
					   'ODO::Jena::Graph::LSet::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	if ( exists( $properties{'LSetType'} )
		 && defined( $properties{'LSetType'} ) )
	{

		unless (
				 UNIVERSAL::isa(
								 $properties{'LSetType'},
								 'ODO::Jena::Graph::Properties::LSetType'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('LSetType') ) {
			return undef;
		}
		$self->properties()->LSetType( $properties{'LSetType'} );
	}
	if ( exists( $properties{'LSetPSet'} )
		 && defined( $properties{'LSetPSet'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'LSetPSet'},
								 'ODO::Jena::Graph::Properties::LSetPSet'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('LSetPSet') ) {
			return undef;
		}
		$self->properties()->LSetPSet( $properties{'LSetPSet'} );
	}
	if ( exists( $properties{'LSetName'} )
		 && defined( $properties{'LSetName'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'LSetName'},
								 'ODO::Jena::Graph::Properties::LSetName'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('LSetName') ) {
			return undef;
		}
		$self->properties()->LSetName( $properties{'LSetName'} );
	}
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#LSet>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#LSet';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = (
					   ''         => '',
					   'LSetType' => 'ODO::Jena::Graph::Properties::LSetType',
					   'LSetPSet' => 'ODO::Jena::Graph::Properties::LSetPSet',
					   'LSetName' => 'ODO::Jena::Graph::Properties::LSetName',
	);
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::LSet::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Class::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Class::PropertiesContainer', );

# Methods
sub LSetType {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::LSetType' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						  ODO::Jena::Graph::Properties::LSetType->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
									  'ODO::Jena::Graph::Properties::LSetType');
}

sub LSetPSet {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::LSetPSet' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						  ODO::Jena::Graph::Properties::LSetPSet->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
									  'ODO::Jena::Graph::Properties::LSetPSet');
}

sub LSetName {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::Graph::Properties::LSetName' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						  ODO::Jena::Graph::Properties::LSetName->objectURI() );
		if ( UNIVERSAL::isa( $value, 'ODO::Node::Literal' ) ) {
			my $stmt =
			  ODO::Statement->new( $parent->subject(), $property, $value );
			$parent->graph()->add($stmt);
		} else {

			# The property's value is a URI with other attached URIs so add them
			# all to the graph
			my $stmt = ODO::Statement->new( $parent->subject(), $property,
											$_[0]->subject() );
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{$value} );
		}
	}
	return $parent->get_property_values(
									  'ODO::Jena::Graph::Properties::LSetName');
}
1;


package ODO::Jena::Graph::Properties::PSetType;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Property;
@ISA = ( 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
				 'ODO::Jena::Graph::Properties::PSetType::PropertiesContainer');
	$self->properties( bless {},
				'ODO::Jena::Graph::Properties::PSetType::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#PSetType>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#PSetType';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::PSetType::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;


package ODO::Jena::Graph::Properties::PSetTable;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Property;
@ISA = ( 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
				'ODO::Jena::Graph::Properties::PSetTable::PropertiesContainer');
	$self->properties( bless {},
			   'ODO::Jena::Graph::Properties::PSetTable::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#PSetTable>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#PSetTable';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::PSetTable::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;


package ODO::Jena::Graph::Properties::LSetType;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Property;
@ISA = ( 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
				 'ODO::Jena::Graph::Properties::LSetType::PropertiesContainer');
	$self->properties( bless {},
				'ODO::Jena::Graph::Properties::LSetType::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#LSetType>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#LSetType';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::LSetType::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;


package ODO::Jena::Graph::Properties::PSetName;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Property;
@ISA = ( 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
				 'ODO::Jena::Graph::Properties::PSetName::PropertiesContainer');
	$self->properties( bless {},
				'ODO::Jena::Graph::Properties::PSetName::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#PSetName>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#PSetName';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::PSetName::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;


package ODO::Jena::Graph::Properties::LSetName;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Property;
@ISA = ( 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
				 'ODO::Jena::Graph::Properties::LSetName::PropertiesContainer');
	$self->properties( bless {},
				'ODO::Jena::Graph::Properties::LSetName::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#LSetName>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#LSetName';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::LSetName::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;


package ODO::Jena::Graph::Properties::GraphName;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Property;
@ISA = ( 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
				'ODO::Jena::Graph::Properties::GraphName::PropertiesContainer');
	$self->properties( bless {},
			   'ODO::Jena::Graph::Properties::GraphName::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#GraphName>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#GraphName';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::GraphName::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;


package ODO::Jena::Graph::Properties::GraphLSet;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;

use ODO::RDFS::Property;
@ISA = ( 'ODO::Jena::Graph::LSet', 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
				'ODO::Jena::Graph::Properties::GraphLSet::PropertiesContainer');
	$self->properties( bless {},
			   'ODO::Jena::Graph::Properties::GraphLSet::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#GraphLSet>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#GraphLSet';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::GraphLSet::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = (
		 'ODO::Jena::Graph::LSet::PropertiesContainer',
		 'ODO::RDFS::Property::PropertiesContainer',
);

# Methods
1;


package ODO::Jena::Graph::Properties::LSetPSet;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Property;
@ISA = ( 'ODO::Jena::Graph::PSet', 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
				 'ODO::Jena::Graph::Properties::LSetPSet::PropertiesContainer');
	$self->properties( bless {},
				'ODO::Jena::Graph::Properties::LSetPSet::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#LSetPSet>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#LSetPSet';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::LSetPSet::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = (
		 'ODO::Jena::Graph::PSet::PropertiesContainer',
		 'ODO::RDFS::Property::PropertiesContainer',
);

# Methods
1;


package ODO::Jena::Graph::Properties::GraphType;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Property;
@ISA = ( 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
				'ODO::Jena::Graph::Properties::GraphType::PropertiesContainer');
	$self->properties( bless {},
			   'ODO::Jena::Graph::Properties::GraphType::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#GraphType>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#GraphType';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::GraphType::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;


package ODO::Jena::Graph::Properties::GraphId;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Property;
@ISA = ( 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
				  'ODO::Jena::Graph::Properties::GraphId::PropertiesContainer');
	$self->properties( bless {},
				 'ODO::Jena::Graph::Properties::GraphId::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#GraphId>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#GraphId';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::GraphId::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;


package ODO::Jena::Graph::Properties::GraphPrefix;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Property;
@ISA = ( 'ODO::RDFS::Property', );

#
# Description: #
# Schema URI: http://jena.hpl.hp.com/2003/04/DB##
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
			  'ODO::Jena::Graph::Properties::GraphPrefix::PropertiesContainer');
	$self->properties( bless {},
			 'ODO::Jena::Graph::Properties::GraphPrefix::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#GraphPrefix>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#GraphPrefix';
}

sub value {
	my $self = shift;
	return $self->subject()
	  if ( UNIVERSAL::isa( $self->subject(), 'ODO::Node::Literal' ) );
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self       = shift;
	my $statements = [];
	foreach my $my_super (@ISA) {
		next
		  unless ( UNIVERSAL::can( $my_super, '__to_statement_array' ) );
		my $super_func = "${my_super}::__to_statement_array";
		push @{$statements}, @{ $self->$super_func() };
	}
	my %properties = ( '' => '', );
	foreach my $propertyName ( keys(%properties) ) {
		next
		  unless ( $propertyName && $propertyName ne '' );
		my $property = $self->properties()->$propertyName();
		foreach my $p ( @{$property} ) {
			my $p_value = $p->value();
			my $property_uri = ODO::Node::Resource->new(
									  $properties{$propertyName}->objectURI() );
			if ( UNIVERSAL::isa( $p_value, 'ODO::Node::Literal' ) ) {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p_value );
			} else {
				push @{$statements},
				  ODO::Statement->new( $self->subject(), $property_uri,
									   $p->subject() );
				push @{$statements}, @{$p_value};
			}
		}
	}
	return $statements;
}
1;

package ODO::Jena::Graph::Properties::GraphPrefix::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
use ODO::RDFS::Property::PropertiesContainer;
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;
