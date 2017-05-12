package ODO::RDFS::Resource;

use strict;
use warnings;

use vars qw( @ISA );
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

use ODO;
use ODO::Query::Simple;
use ODO::Statement::Group;
use ODO::Ontology::RDFS::BaseClass;

@ISA = (  'ODO::Ontology::RDFS::BaseClass', );

#
# Description: The class resource, everything.
#
# Schema URI: http://www.w3.org/2000/01/rdf-schema#
#
sub new {
	my $self = shift;
	my ($resource, $graph, %properties) = @_;
	
	$self = $self->SUPER::new(@_);
	
	return undef
		unless(ref $self);
	
	$self->propertyContainerName( 'ODO::RDFS::Resource::PropertiesContainer' );
	$self->properties(bless {}, 'ODO::RDFS::Resource::PropertiesContainer');

	$self->properties()->{'parent'} = $self;



	if(   exists($properties{'comment'})
	   && defined($properties{'comment'})) {
	
		unless(UNIVERSAL::isa($properties{'comment'}, 'ODO::RDFS::Properties::comment')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('comment')) {
			return undef;
		}
		
		$self->properties()->comment( $properties{'comment'} );
	}



	if(   exists($properties{'label'})
	   && defined($properties{'label'})) {
	
		unless(UNIVERSAL::isa($properties{'label'}, 'ODO::RDFS::Properties::label')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('label')) {
			return undef;
		}
		
		$self->properties()->label( $properties{'label'} );
	}



	if(   exists($properties{'member'})
	   && defined($properties{'member'})) {
	
		unless(UNIVERSAL::isa($properties{'member'}, 'ODO::RDFS::Properties::member')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('member')) {
			return undef;
		}
		
		$self->properties()->member( $properties{'member'} );
	}



	if(   exists($properties{'seeAlso'})
	   && defined($properties{'seeAlso'})) {
	
		unless(UNIVERSAL::isa($properties{'seeAlso'}, 'ODO::RDFS::Properties::seeAlso')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('seeAlso')) {
			return undef;
		}
		
		$self->properties()->seeAlso( $properties{'seeAlso'} );
	}



	if(   exists($properties{'isDefinedBy'})
	   && defined($properties{'isDefinedBy'})) {
	
		unless(UNIVERSAL::isa($properties{'isDefinedBy'}, 'ODO::RDFS::Properties::isDefinedBy')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('isDefinedBy')) {
			return undef;
		}
		
		$self->properties()->isDefinedBy( $properties{'isDefinedBy'} );
	}



	if(   exists($properties{'type'})
	   && defined($properties{'type'})) {
	
		unless(UNIVERSAL::isa($properties{'type'}, 'ODO::RDFS::Properties::type')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('type')) {
			return undef;
		}
		
		$self->properties()->type( $properties{'type'} );
	}



	if(   exists($properties{'value'})
	   && defined($properties{'value'})) {
	
		unless(UNIVERSAL::isa($properties{'value'}, 'ODO::RDFS::Properties::value')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('value')) {
			return undef;
		}
		
		$self->properties()->value( $properties{'value'} );
	}


	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://www.w3.org/2000/01/rdf-schema#Resource>)';
}

sub objectURI {
	return 'http://www.w3.org/2000/01/rdf-schema#Resource';
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
	
	my %properties = (''=> '', 'comment'=> 'ODO::RDFS::Properties::comment',  'label'=> 'ODO::RDFS::Properties::label',  'member'=> 'ODO::RDFS::Properties::member',  'seeAlso'=> 'ODO::RDFS::Properties::seeAlso',  'isDefinedBy'=> 'ODO::RDFS::Properties::isDefinedBy',  'type'=> 'ODO::RDFS::Properties::type',  'value'=> 'ODO::RDFS::Properties::value', );
	
	foreach my $propertyName (keys(%properties)) {

		next 
			unless($propertyName && $propertyName ne '');
		
		my $property;
		eval {$property = $self->properties()->$propertyName()};
		next unless $@;
		
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
