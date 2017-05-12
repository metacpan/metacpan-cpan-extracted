package ODO::RDFS::Property;

use strict;
use warnings;

use vars qw( @ISA );
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::RDFS::Resource;

@ISA = (  'ODO::RDFS::Resource', );

#
# Description: The class of RDF properties.
#
# Schema URI: http://www.w3.org/1999/02/22-rdf-syntax-ns#
#
sub new {
	my $self = shift;
	my ($resource, $graph, %properties) = @_;
	
	$self = $self->SUPER::new(@_);
	
	return undef
		unless(ref $self);
	
	$self->propertyContainerName( 'ODO::RDFS::Property::PropertiesContainer' );
	$self->properties(bless {}, 'ODO::RDFS::Property::PropertiesContainer');

	$self->properties()->{'parent'} = $self;



	if(   exists($properties{'subPropertyOf'})
	   && defined($properties{'subPropertyOf'})) {
	
		unless(UNIVERSAL::isa($properties{'subPropertyOf'}, 'ODO::RDFS::Properties::subPropertyOf')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('subPropertyOf')) {
			return undef;
		}
		
		$self->properties()->subPropertyOf( $properties{'subPropertyOf'} );
	}



	if(   exists($properties{'range'})
	   && defined($properties{'range'})) {
	
		unless(UNIVERSAL::isa($properties{'range'}, 'ODO::RDFS::Properties::range')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('range')) {
			return undef;
		}
		
		$self->properties()->range( $properties{'range'} );
	}



	if(   exists($properties{'domain'})
	   && defined($properties{'domain'})) {
	
		unless(UNIVERSAL::isa($properties{'domain'}, 'ODO::RDFS::Properties::domain')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('domain')) {
			return undef;
		}
		
		$self->properties()->domain( $properties{'domain'} );
	}


	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://www.w3.org/1999/02/22-rdf-syntax-ns#Property>)';
}

sub objectURI {
	return 'http://www.w3.org/1999/02/22-rdf-syntax-ns#Property';
}

sub value {
	my $self = shift;
	
	return $self->subject()
		if(UNIVERSAL::isa($self->subject(), 'ODO::Node::Literal'));
	
	return $self->__to_statement_array();
}

sub __to_statement_array {
	my $self = shift;
	
	my $statements = [];
	
	foreach my $my_super (@ISA) {
	
		next
			unless(UNIVERSAL::can($my_super, '__to_statement_array'));
		
		my $super_func = "${my_super}::__to_statement_array";
		push @{ $statements }, @{ $self->$super_func() };
	}
	
	my %properties = (''=> '', 'subPropertyOf'=> 'ODO::RDFS::Properties::subPropertyOf',  'range'=> 'ODO::RDFS::Properties::range',  'domain'=> 'ODO::RDFS::Properties::domain', );
	
	foreach my $propertyName (keys(%properties)) {

		next 
			unless($propertyName && $propertyName ne '');
		
		my $property = $self->properties()->$propertyName();
		
		foreach my $p (@{ $property }) {
			my $p_value = $p->value();
			
			my $property_uri = ODO::Node::Resource->new($properties{$propertyName}->objectURI() );
			if(UNIVERSAL::isa($p_value, 'ODO::Node::Literal')) {
				push @{ $statements }, ODO::Statement->new($self->subject(), $property_uri, $p_value);
			}
			else {
				push @{ $statements }, ODO::Statement->new($self->subject(), $property_uri, $p->subject());
				push @{ $statements }, @{ $p_value };
			}
		}
	}
	
	return $statements;
}

1;
