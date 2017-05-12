package ODO::RDFS::Statement;

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
# Description: The class of RDF statements.#
# Schema URI: http://www.w3.org/1999/02/22-rdf-syntax-ns#
#
sub new {
	my $self = shift;
	my ($resource, $graph, %properties) = @_;
	
	$self = $self->SUPER::new(@_);
	
	return undef
		unless(ref $self);
	
	$self->propertyContainerName( 'ODO::RDFS::Statement::PropertiesContainer' );
	$self->properties(bless {}, 'ODO::RDFS::Statement::PropertiesContainer');

	$self->properties()->{'parent'} = $self;



	if(   exists($properties{'subject'})
	   && defined($properties{'subject'})) {
	
		unless(UNIVERSAL::isa($properties{'subject'}, 'ODO::RDFS::Properties::subject')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('subject')) {
			return undef;
		}
		
		$self->properties()->subject( $properties{'subject'} );
	}



	if(   exists($properties{'object'})
	   && defined($properties{'object'})) {
	
		unless(UNIVERSAL::isa($properties{'object'}, 'ODO::RDFS::Properties::object')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('object')) {
			return undef;
		}
		
		$self->properties()->object( $properties{'object'} );
	}



	if(   exists($properties{'predicate'})
	   && defined($properties{'predicate'})) {
	
		unless(UNIVERSAL::isa($properties{'predicate'}, 'ODO::RDFS::Properties::predicate')) {
			return undef;
		}
		
		unless($self->can('properties')) {
			return undef;
		}
		
		unless($self->properties()->can('predicate')) {
			return undef;
		}
		
		$self->properties()->predicate( $properties{'predicate'} );
	}


	return $self;
}

sub queryString {
	return '(?subj, rdf:type, <http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement>)';
}

sub objectURI {
	return 'http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement';
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
	
	my %properties = (''=> '', 'subject'=> 'ODO::RDFS::Properties::subject',  'object'=> 'ODO::RDFS::Properties::object',  'predicate'=> 'ODO::RDFS::Properties::predicate', );
	
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
