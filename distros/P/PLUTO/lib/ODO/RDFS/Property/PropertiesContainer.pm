package ODO::RDFS::Property::PropertiesContainer;

use strict;
use warnings;

use vars qw( $AUTOLOAD @ISA );
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;
use ODO::RDFS::Resource::PropertiesContainer;

@ISA = (  'ODO::RDFS::Resource::PropertiesContainer', );

# Methods


sub subPropertyOf {
	my $self = shift;

	my $parent = $self->{'parent'};
	unless($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}

	if(   scalar(@_) > 0
	   && UNIVERSAL::isa($_[0], 'ODO::RDFS::Properties::subPropertyOf')) {

		my $value = $_[0]->value();
		
		my $property = ODO::Node::Resource->new( ODO::RDFS::Properties::subPropertyOf->objectURI() );
		if(UNIVERSAL::isa($value, 'ODO::Node::Literal')) {			
			my $stmt = ODO::Statement->new($parent->subject(), $property, $value);
			$parent->graph()->add($stmt);
		}
		else {
			# The property's value is a URI with other attached URIs so add them 
			# all to the graph
			my $stmt = ODO::Statement->new($parent->subject(), $property, $_[0]->subject());
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{ $value } );
		}
	}
	
	return $parent->get_property_values( 'ODO::RDFS::Properties::subPropertyOf' );
}




sub range {
	my $self = shift;

	my $parent = $self->{'parent'};
	unless($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}

	if(   scalar(@_) > 0
	   && UNIVERSAL::isa($_[0], 'ODO::RDFS::Properties::range')) {

		my $value = $_[0]->value();
		
		my $property = ODO::Node::Resource->new( ODO::RDFS::Properties::range->objectURI() );
		if(UNIVERSAL::isa($value, 'ODO::Node::Literal')) {			
			my $stmt = ODO::Statement->new($parent->subject(), $property, $value);
			$parent->graph()->add($stmt);
		}
		else {
			# The property's value is a URI with other attached URIs so add them 
			# all to the graph
			my $stmt = ODO::Statement->new($parent->subject(), $property, $_[0]->subject());
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{ $value } );
		}
	}
	
	return $parent->get_property_values( 'ODO::RDFS::Properties::range' );
}




sub domain {
	my $self = shift;

	my $parent = $self->{'parent'};
	unless($parent) {
		die('Fatal error in property container: parent object is not defined!');
	}

	if(   scalar(@_) > 0
	   && UNIVERSAL::isa($_[0], 'ODO::RDFS::Properties::domain')) {

		my $value = $_[0]->value();
		
		my $property = ODO::Node::Resource->new( ODO::RDFS::Properties::domain->objectURI() );
		if(UNIVERSAL::isa($value, 'ODO::Node::Literal')) {			
			my $stmt = ODO::Statement->new($parent->subject(), $property, $value);
			$parent->graph()->add($stmt);
		}
		else {
			# The property's value is a URI with other attached URIs so add them 
			# all to the graph
			my $stmt = ODO::Statement->new($parent->subject(), $property, $_[0]->subject());
			$parent->graph()->add($stmt);
			$parent->graph()->add( @{ $value } );
		}
	}
	
	return $parent->get_property_values( 'ODO::RDFS::Properties::domain' );
}






1;
