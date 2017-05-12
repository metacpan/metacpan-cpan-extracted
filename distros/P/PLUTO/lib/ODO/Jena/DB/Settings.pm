package ODO::Jena::DB::Settings;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::Ontology::RDFS::BaseClass;

@ISA = ( 'ODO::Ontology::RDFS::BaseClass', );
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;
#
# Description: 
#
# Schema URI: http://ibm-slrp.sourceforge.net/uris/odo/2007/01/jena-db-schema#
#
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
								'ODO::Jena::DB::Settings::PropertiesContainer');
	$self->properties( bless {},
					   'ODO::Jena::DB::Settings::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	if ( exists( $properties{'Graph'} )
		 && defined( $properties{'Graph'} ) )
	{

		unless (
				 UNIVERSAL::isa(
								 $properties{'Graph'},
								 'ODO::Jena::DB::Properties::Graph'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('Graph') ) {
			return undef;
		}
		$self->properties()->Graph( $properties{'Graph'} );
	}
	if ( exists( $properties{'FormatDate'} )
		 && defined( $properties{'FormatDate'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'FormatDate'},
								 'ODO::Jena::DB::Properties::FormatDate'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('FormatDate') ) {
			return undef;
		}
		$self->properties()->FormatDate( $properties{'FormatDate'} );
	}
	if ( exists( $properties{'SystemGraph'} )
		 && defined( $properties{'SystemGraph'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'SystemGraph'},
								 'ODO::Jena::DB::Properties::SystemGraph'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('SystemGraph') ) {
			return undef;
		}
		$self->properties()->SystemGraph( $properties{'SystemGraph'} );
	}
	if ( exists( $properties{'TableNamePrefix'} )
		 && defined( $properties{'TableNamePrefix'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'TableNamePrefix'},
								 'ODO::Jena::DB::Properties::TableNamePrefix'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('TableNamePrefix') ) {
			return undef;
		}
		$self->properties()->TableNamePrefix( $properties{'TableNamePrefix'} );
	}
	if ( exists( $properties{'IndexKeyLength'} )
		 && defined( $properties{'IndexKeyLength'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'IndexKeyLength'},
								 'ODO::Jena::DB::Properties::IndexKeyLength'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('IndexKeyLength') ) {
			return undef;
		}
		$self->properties()->IndexKeyLength( $properties{'IndexKeyLength'} );
	}
	if ( exists( $properties{'LongObjectLength'} )
		 && defined( $properties{'LongObjectLength'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'LongObjectLength'},
								 'ODO::Jena::DB::Properties::LongObjectLength'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('LongObjectLength') ) {
			return undef;
		}
		$self->properties()
		  ->LongObjectLength( $properties{'LongObjectLength'} );
	}
	if ( exists( $properties{'IsTransactionDb'} )
		 && defined( $properties{'IsTransactionDb'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'IsTransactionDb'},
								 'ODO::Jena::DB::Properties::IsTransactionDb'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('IsTransactionDb') ) {
			return undef;
		}
		$self->properties()->IsTransactionDb( $properties{'IsTransactionDb'} );
	}
	if ( exists( $properties{'EngineType'} )
		 && defined( $properties{'EngineType'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'EngineType'},
								 'ODO::Jena::DB::Properties::EngineType'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('EngineType') ) {
			return undef;
		}
		$self->properties()->EngineType( $properties{'EngineType'} );
	}
	if ( exists( $properties{'CompressURILength'} )
		 && defined( $properties{'CompressURILength'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'CompressURILength'},
								 'ODO::Jena::DB::Properties::CompressURILength'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('CompressURILength') ) {
			return undef;
		}
		$self->properties()
		  ->CompressURILength( $properties{'CompressURILength'} );
	}
	if ( exists( $properties{'LayoutVersion'} )
		 && defined( $properties{'LayoutVersion'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'LayoutVersion'},
								 'ODO::Jena::DB::Properties::LayoutVersion'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('LayoutVersion') ) {
			return undef;
		}
		$self->properties()->LayoutVersion( $properties{'LayoutVersion'} );
	}
	if ( exists( $properties{'DoCompressURI'} )
		 && defined( $properties{'DoCompressURI'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'DoCompressURI'},
								 'ODO::Jena::DB::Properties::DoCompressURI'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('DoCompressURI') ) {
			return undef;
		}
		$self->properties()->DoCompressURI( $properties{'DoCompressURI'} );
	}
	if ( exists( $properties{'DriverVersion'} )
		 && defined( $properties{'DriverVersion'} ) )
	{
		unless (
				 UNIVERSAL::isa(
								 $properties{'DriverVersion'},
								 'ODO::Jena::DB::Properties::DriverVersion'
				 )
		  )
		{
			return undef;
		}
		unless ( $self->can('properties') ) {
			return undef;
		}
		unless ( $self->properties()->can('DriverVersion') ) {
			return undef;
		}
		$self->properties()->DriverVersion( $properties{'DriverVersion'} );
	}
	return $self;
}

sub queryString {
	return
'(?subj, rdf:type, <http://ibm-slrp.sourceforge.net/uris/odo/2007/01/jena-db-schema#Settings>)';
}

sub objectURI {
	return
'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/jena-db-schema#Settings';
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
		  ''                  => '',
		  'Graph'             => 'ODO::Jena::DB::Properties::Graph',
		  'FormatDate'        => 'ODO::Jena::DB::Properties::FormatDate',
		  'SystemGraph'       => 'ODO::Jena::DB::Properties::SystemGraph',
		  'TableNamePrefix'   => 'ODO::Jena::DB::Properties::TableNamePrefix',
		  'IndexKeyLength'    => 'ODO::Jena::DB::Properties::IndexKeyLength',
		  'LongObjectLength'  => 'ODO::Jena::DB::Properties::LongObjectLength',
		  'IsTransactionDb'   => 'ODO::Jena::DB::Properties::IsTransactionDb',
		  'EngineType'        => 'ODO::Jena::DB::Properties::EngineType',
		  'CompressURILength' => 'ODO::Jena::DB::Properties::CompressURILength',
		  'LayoutVersion'     => 'ODO::Jena::DB::Properties::LayoutVersion',
		  'DoCompressURI'     => 'ODO::Jena::DB::Properties::DoCompressURI',
		  'DriverVersion'     => 'ODO::Jena::DB::Properties::DriverVersion',
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

package ODO::Jena::DB::Settings::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Class::PropertiesContainer', );

# Methods
sub Graph {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::DB::Properties::Graph' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
								ODO::Jena::DB::Properties::Graph->objectURI() );
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
	return $parent->get_property_values('ODO::Jena::DB::Properties::Graph');
}

sub FormatDate {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::DB::Properties::FormatDate' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						   ODO::Jena::DB::Properties::FormatDate->objectURI() );
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
									   'ODO::Jena::DB::Properties::FormatDate');
}

sub SystemGraph {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::DB::Properties::SystemGraph' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						  ODO::Jena::DB::Properties::SystemGraph->objectURI() );
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
									  'ODO::Jena::DB::Properties::SystemGraph');
}

sub TableNamePrefix {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		&& UNIVERSAL::isa( $_[0], 'ODO::Jena::DB::Properties::TableNamePrefix' )
	  )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
					  ODO::Jena::DB::Properties::TableNamePrefix->objectURI() );
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
								  'ODO::Jena::DB::Properties::TableNamePrefix');
}

sub IndexKeyLength {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::DB::Properties::IndexKeyLength' )
	  )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
					   ODO::Jena::DB::Properties::IndexKeyLength->objectURI() );
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
								   'ODO::Jena::DB::Properties::IndexKeyLength');
}

sub LongObjectLength {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0],
							'ODO::Jena::DB::Properties::LongObjectLength' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
					 ODO::Jena::DB::Properties::LongObjectLength->objectURI() );
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
								 'ODO::Jena::DB::Properties::LongObjectLength');
}

sub IsTransactionDb {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		&& UNIVERSAL::isa( $_[0], 'ODO::Jena::DB::Properties::IsTransactionDb' )
	  )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
					  ODO::Jena::DB::Properties::IsTransactionDb->objectURI() );
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
								  'ODO::Jena::DB::Properties::IsTransactionDb');
}

sub EngineType {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0], 'ODO::Jena::DB::Properties::EngineType' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						   ODO::Jena::DB::Properties::EngineType->objectURI() );
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
									   'ODO::Jena::DB::Properties::EngineType');
}

sub CompressURILength {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		 && UNIVERSAL::isa( $_[0],
							'ODO::Jena::DB::Properties::CompressURILength' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
					ODO::Jena::DB::Properties::CompressURILength->objectURI() );
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
								'ODO::Jena::DB::Properties::CompressURILength');
}

sub LayoutVersion {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		&& UNIVERSAL::isa( $_[0], 'ODO::Jena::DB::Properties::LayoutVersion' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						ODO::Jena::DB::Properties::LayoutVersion->objectURI() );
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
									'ODO::Jena::DB::Properties::LayoutVersion');
}

sub DoCompressURI {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		&& UNIVERSAL::isa( $_[0], 'ODO::Jena::DB::Properties::DoCompressURI' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						ODO::Jena::DB::Properties::DoCompressURI->objectURI() );
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
									'ODO::Jena::DB::Properties::DoCompressURI');
}

sub DriverVersion {
	my $self   = shift;
	my $parent = $self->{'parent'};
	unless ($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}
	if ( scalar(@_) > 0
		&& UNIVERSAL::isa( $_[0], 'ODO::Jena::DB::Properties::DriverVersion' ) )
	{
		my $value = $_[0]->value();
		my $property =
		  ODO::Node::Resource->new(
						ODO::Jena::DB::Properties::DriverVersion->objectURI() );
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
									'ODO::Jena::DB::Properties::DriverVersion');
}
1;

package ODO::Jena::DB::Properties::DriverVersion;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

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
	$self->propertyContainerName(
			   'ODO::Jena::DB::Properties::DriverVersion::PropertiesContainer');
	$self->properties( bless {},
			  'ODO::Jena::DB::Properties::DriverVersion::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return
	  '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#DriverVersion>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#DriverVersion';
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

package ODO::Jena::DB::Properties::DriverVersion::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::IndexKeyLength;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

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
	$self->propertyContainerName(
			  'ODO::Jena::DB::Properties::IndexKeyLength::PropertiesContainer');
	$self->properties( bless {},
			 'ODO::Jena::DB::Properties::IndexKeyLength::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return
	  '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#IndexKeyLength>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#IndexKeyLength';
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

package ODO::Jena::DB::Properties::IndexKeyLength::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::FormatDate;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

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
	$self->propertyContainerName(
				  'ODO::Jena::DB::Properties::FormatDate::PropertiesContainer');
	$self->properties( bless {},
				 'ODO::Jena::DB::Properties::FormatDate::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#FormatDate>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#FormatDate';
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

package ODO::Jena::DB::Properties::FormatDate::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::CompressURILength;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

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
	$self->propertyContainerName(
		   'ODO::Jena::DB::Properties::CompressURILength::PropertiesContainer');
	$self->properties( bless {},
		  'ODO::Jena::DB::Properties::CompressURILength::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return
'(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#CompressURILength>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#CompressURILength';
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

package ODO::Jena::DB::Properties::CompressURILength::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::TableNamePrefix;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

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
	$self->propertyContainerName(
			 'ODO::Jena::DB::Properties::TableNamePrefix::PropertiesContainer');
	$self->properties( bless {},
			'ODO::Jena::DB::Properties::TableNamePrefix::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return
	  '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#TableNamePrefix>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#TableNamePrefix';
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

package ODO::Jena::DB::Properties::TableNamePrefix::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::EngineType;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

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
	$self->propertyContainerName(
				  'ODO::Jena::DB::Properties::EngineType::PropertiesContainer');
	$self->properties( bless {},
				 'ODO::Jena::DB::Properties::EngineType::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#EngineType>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#EngineType';
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

package ODO::Jena::DB::Properties::EngineType::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::SystemGraph;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

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
	$self->propertyContainerName(
				 'ODO::Jena::DB::Properties::SystemGraph::PropertiesContainer');
	$self->properties( bless {},
				'ODO::Jena::DB::Properties::SystemGraph::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#SystemGraph>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#SystemGraph';
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

package ODO::Jena::DB::Properties::SystemGraph::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::Graph;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

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
	$self->propertyContainerName(
					   'ODO::Jena::DB::Properties::Graph::PropertiesContainer');
	$self->properties( bless {},
					  'ODO::Jena::DB::Properties::Graph::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#Graph>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#Graph';
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

package ODO::Jena::DB::Properties::Graph::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::DoCompressURI;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

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
	$self->propertyContainerName(
			   'ODO::Jena::DB::Properties::DoCompressURI::PropertiesContainer');
	$self->properties( bless {},
			  'ODO::Jena::DB::Properties::DoCompressURI::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return
	  '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#DoCompressURI>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#DoCompressURI';
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

package ODO::Jena::DB::Properties::DoCompressURI::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::IsTransactionDb;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );
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
	$self->propertyContainerName(
			 'ODO::Jena::DB::Properties::IsTransactionDb::PropertiesContainer');
	$self->properties( bless {},
			'ODO::Jena::DB::Properties::IsTransactionDb::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return
	  '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#IsTransactionDb>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#IsTransactionDb';
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

package ODO::Jena::DB::Properties::IsTransactionDb::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::LayoutVersion;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

#
# Description: 
#
# Schema URI: http://jena.hpl.hp.com/2003/04/DB
#
#
sub new {
	my $self = shift;
	my ( $resource, $graph, %properties ) = @_;
	$self = $self->SUPER::new(@_);
	return undef
	  unless ( ref $self );
	$self->propertyContainerName(
			   'ODO::Jena::DB::Properties::LayoutVersion::PropertiesContainer');
	$self->properties( bless {},
			  'ODO::Jena::DB::Properties::LayoutVersion::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return
	  '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#LayoutVersion>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#LayoutVersion';
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

package ODO::Jena::DB::Properties::LayoutVersion::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;

package ODO::Jena::DB::Properties::LongObjectLength;
use strict;
use warnings;
use vars qw( @ISA );
use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
@ISA = ( 'ODO::RDFS::Property', );

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
	$self->propertyContainerName(
			'ODO::Jena::DB::Properties::LongObjectLength::PropertiesContainer');
	$self->properties( bless {},
		   'ODO::Jena::DB::Properties::LongObjectLength::PropertiesContainer' );
	$self->properties()->{'parent'} = $self;
	return $self;
}

sub queryString {
	return
	  '(?subj, rdf:type, <http://jena.hpl.hp.com/2003/04/DB#LongObjectLength>)';
}

sub objectURI {
	return 'http://jena.hpl.hp.com/2003/04/DB#LongObjectLength';
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

package ODO::Jena::DB::Properties::LongObjectLength::PropertiesContainer;
use strict;
use warnings;
use vars qw( $AUTOLOAD @ISA );
@ISA = ( 'ODO::RDFS::Property::PropertiesContainer', );

# Methods
1;
