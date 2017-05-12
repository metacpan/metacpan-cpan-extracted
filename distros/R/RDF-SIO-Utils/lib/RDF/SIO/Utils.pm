package RDF::SIO::Utils;
{
  $RDF::SIO::Utils::VERSION = '0.003';
}
BEGIN {
  $RDF::SIO::Utils::VERSION = '0.003';
}
use strict;
use Carp;
use RDF::SIO::Utils::Trine;
use RDF::SIO::Utils::Constants;

use vars qw($AUTOLOAD @ISA);

use vars qw /$VERSION/;


my $xsd = "http://www.w3.org/2001/XMLSchema#";


=head1 NAME

RDF::SIO::Utils - tools for working with the SIO ontology

=head1 SYNOPSIS

 use RDF::SIO::Utils;

 my $SIO = RDF::SIO::Utils->new();
 
 # auto created RDF::SIO::Utils::Trine is there
 my $m = $SIO->Trine->temporary_model(); 
 
 # create a subject to execute annotation and parsing on
 my $s = $SIO->Trine->iri('http://mydata.com/patient101');

 # we want to add a blood pressure attribute to this patient, using
 # the "hasBloodPressure" predicate from our own ontology
 # SIO::Utils will automatically add the SIO:has_attribute
 # predicate as a second connection to this node
 my $BloodPressure = $SIO->addAttribute(model => $m,
                   node => $s,
                   predicate => "http://myontology.org/pred/hasBloodPressure",
                   attributeType => "http://myontology.org/class/BloodPressure",
                   );


 #this is how to handle the success/failure of most calls in this module
 if ($BloodPressure){
    print "Blood Pressure attribute ID is ",$BloodPressure->as_string,"\n";
 } else {
    print $SIO->error_message(), "\n";
    die;  # or do something useful...
 }

 my $Measurement = $SIO->addMeasurement(model => $m,
                   node => $BloodPressure,
                   attributeID => "http://mydatastore.org/observation1",
                   value => "115",
                   valueType => "^^int",
                   unit => "mmHg"
                   );

 print "Measurement node ID is ",$Measurement->as_string,"\n";

 print "extracting info from this Measurement:\n";
 my ($value, $unit) = $SIO->getUnitValue(model => $m, node => $Measurement);
 print "Measurement was - Value:  $value\nUnit:  $unit\n\n";
    

 my $types = $SIO->getAttributeTypes(
        model => $m,
        node => $s);
 print "\n\nAll Attribute Types:\n ";
 print join "\n", @$types, "\n";


 my $bp = $SIO->getAttributesByType(
        model =>$m,
        node => $s,
        attributeType =>"http://myontology.org/class/BloodPressure",  );
 print "Nodes of type 'Blood Pressure':\n";
 print join "\n", @$bp, "\n";

 print "\nand the piece de resistance...
       traverse the whole shebang in one call!\n";
       
 my $data = $SIO->getAttributeMeasurements(
    model => $m,
    node => $s,
    attributeType => "http://myontology.org/class/BloodPressure"
    );

 foreach my $data_point(@$data){
    my ($value, $unit) = ("", "");
    ($value, $unit) = @$data_point;
    print "found Blood Pressure data point:  $value, $unit\n";
 }

 # to dump out the entire model as RDF
 use RDF::Trine::Serializer::RDFXML;
 my $serializer = RDF::Trine::Serializer::RDFXML->new( );
 print $serializer->serialize_model_to_string($m);
 print "\n\n"; 


=cut

=head1 DESCRIPTION

The Semantic Science Integrated Ontology (SIO) is an upper-ontology
designed specifically to represent scientific data.  This module helps
users create data compliant with this ontology, and parse that data


=head1 AUTHORS

Mark Wilkinson (markw at illuminae dot com)

=cut

=head1 METHODS


=head2 new

 Usage     :	my $SIO = SIO::Utils->new();
 Function  :    Create a helper module for the SIO ontology
 Returns   :	a helper module for the SIO ontology
 Args      :    none


=cut

{

	# Encapsulated:
	# DATA
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		error_message          => [ undef, 'read/write' ],
		Trine		       => [ undef, 'read/write' ],

	  );

	#_____________________________________________________________
	# METHODS, to operate on encapsulated class data
	# Is a specified object attribute accessible in a given mode
	sub _accessible {
		my ( $self, $attr, $mode ) = @_;
		$_attr_data{$attr}[1] =~ /$mode/;
	}

	# Classwide default value for a specified object attribute
	sub _default_for {
		my ( $self, $attr ) = @_;
		$_attr_data{$attr}[0];
	}

	# List of names of all specified object attributes
	sub _standard_keys {
		keys %_attr_data;
	}


}


sub new {
  my ( $caller, %args ) = @_;
  my $caller_is_obj = ref( $caller );
  return $caller if $caller_is_obj;
  my $class = $caller_is_obj || $caller;
  my $proxy;
  my $self = bless {}, $class;
  foreach my $attrname ( $self->_standard_keys ) {
    if ( exists $args{$attrname} ) {
      $self->{$attrname} = $args{$attrname};
    } elsif ( $caller_is_obj ) {
      $self->{$attrname} = $caller->{$attrname};
    } else {
      $self->{$attrname} = $self->_default_for( $attrname );
    }
  }
  my $Trine = RDF::SIO::Utils::Trine->new();
  $self->Trine($Trine);

  return $self;
}


=head2 addAttribute

 Usage     :	$SIO->addAttribute(%args);
 Function  :    add a new attribute to an SIO entity
 Returns   :	0 on failure (check $SIO->error_message after failure for
                details.  Returns the attribute's Trine node on success.
 Args      :    model - an RDF::Trine::Model to hold results
		node  - the RDF::Trine::Node to which we will attach the
                        attribute.  This is the "subject" of the triples,
			and (duh) should be part of the model above.
		predicate - optional, your desired predicate URI.
		            Defaults to sio:hasAttribute if not provided.
                attributeID - optional,the URI of your attribute,
		              defaults to a bnode, but MUST be typed
		attributeType - The rdf:type of your attribute as a URI
		value - optional, the value (e.g. 17 or "hi")
		valueType - optional, and this varies depending on
		            what "value:" is.  If it is a string, then
			    enter the language here using "lang:xx" (e.g.
			    valueType = 'lang:en').  If it is a non-string,
			    then enter its xsd:type in turtle syntax
			    (e.g. valueType='^^int')
		unit - optional, URI to a Unit Ontology type, or a string
		context - optional, URI of the context (for n-quads and named graphs)
 Description:   Creates the following structure:
 
                   node
                      has_attribute
                             attributeID/_bnode
                                     [has_value value]
                                     [has_unit  unit]
                                     [rdf_type  type] (dflt SIO:attribute)


=cut

sub addAttribute {
	my ($self, %args) = @_;

	my $model = $args{model};
	
	my $subject = $args{node};  # subject
	my $attr_uri = $args{attributeID}; # object -> will become a _bnode if not specified
	my $val = $args{value};  # some numerical or string value
	my $unit = $args{unit};    # the unit of measure if numerical value
	my $attribute_type = $args{attributeType};  # specification of what "type" of object we have
	my $value_type = $args{valueType};  # specification of what "type" of value we have string, non-string, or OWL class
	my $pred = $args{predicate};   # what is the predicate connecting this attribute to the subject node?
	my $context = $args{context};

	
	my $attribute;  # the URI of the attribute node as a Trine
	my $predicate;  # the URI of the predicate, as a Trine
	my $value;   # literal value as a trine
	my $classType;  # the rdf:type of the attributeID ($attribute_type) as a Trine

	# create a trine spewer
	my $T = $self->Trine;

	# deal with context first
	if ($context && !($context=~ /^http:/)){
		$self->error_message("your context, if provided, must be a URI.");
		return 0;
	}
	if ($context){
		$context = $T->iri($context);
	}

	
	# deal with the attribute node - need everything as a Trine before we start building he model
	
	if ($attr_uri){  # if they give us a URI, it should be a URI and they should give us a type
		unless ($attr_uri =~ /^http:/){
			$self->error_message("Your attributeID isn't a URI... it should be");
			return 0;
		}
		unless ($attribute_type && ($attribute_type =~ /^http:/)){
			$self->error_message("The attribute type for $attr_uri isn't specified, or isn't a URI.  That's not very polite!  Please don't give me a URI and not tell me what kind of 'thing' it represents!");
			return 0;
		}
		$attribute = $T->iri($attr_uri);  # make the URI into a trine
		$classType = $T->iri($attribute_type);  # create an rdf:type for it - whatever they said
		
	} else {  # if they don't give us a URI (bnode), they must still give us a type
		if (!$attribute_type || !($attribute_type =~ /^http:/) ){ # if there's a value, but not an attribute type or the attribute type isn't a URI, then fail
			$self->error_message("Not enough information provided to create the statements. You must tell me the type of attribute (attributeType)");
			return 0;
		}
		
		$attribute = $T->blank();  # create a bnode for the attribute
		$classType = $T->iri($attribute_type);  # and set classtype to whatever they said
		
	}
	

	if ($pred && !($pred=~ /^http:/)){
		$self->error_message("your predicate, if provided, must be a URI.");
		return 0;
	}
	if ($pred){
		$predicate = $T->iri($pred);
	} else {
		$predicate = $T->iri(SIO_HAS_ATTR);
	}
	
	

	# deal with the unit node - need everything as a Trine before we start building the model
	if ($unit && !$val){
		$self->error_message("Ummmm... a unit but no value?  I dont' know what to do with that");
		return 0;
		
	}
	if ($unit && ($unit =~ /http:/)) { # the unit is a reference to some unit ontology, apparently
		$unit = $T->iri($unit);   # dont' ask questions, just make it a URI Trine
		
	} elsif ($unit) {   # then I guess it's a literal??
		$unit = $T->literal($unit);  # don't know what kind of literal, so pass only one arg
	}


	# deal with the value node - need everything as a Trine before we start building the model
	
	if ($value_type && ($value_type =~ /^\^\^(\S+)/)){  # it's a non-string literal (e.g. ^^int)
		$value = $T->literal($val, "", $xsd.$1);
		
	} elsif ($value_type && ($value_type =~ /^lang:(\S+)/)) {  # it's a string literal, language provided (eg. lang:en)
		$value = $T->literal($val, $1, "");
		
	} elsif ($value_type) {  # it's a string literal, language provided (eg. lang:en)
		$self->error_message("you provided a value type that isn't recognized. Either a language (e.g. lang:en) or an xsd type  (e.g. ^^int) are the only options allowed.");
		return 0;
		
	} elsif ($val) {   # then I guess it's a literal??
		$value = $T->literal($val);  # don't know what kind of literal, so pass only one arg
	} else {
		$value = "";  # this will be caught and ignored by the updateModel routine
	}
	


	&_updateModel($T, $model, $subject, $predicate, $attribute, $classType, $value, $unit, $context );
	
	return $attribute;
	
}


=head2 addMeasurement

 Usage     :	$SIO->addMeasurement(%args);
 Function  :    A specialized type of addAttribute - rdf types and
                predicates are auto-selected to be compliant with SIO
 Returns   :	0 on failure (check $SIO->error_message after failure for
                details.)  Returns the Measurement's Trine node on success.
 Args      :    model - an RDF::Trine::Model to hold results
		node  - the RDF::Trine::Node to which we will attach the
                        attribute.  This is the "subject" of the triples,
			and (duh) should be part of the model above.
                attributeID - optional,the URI of your attribute,
		              defaults to a bnode.
		value - required, the value of the measurement.  In SIO, all
		        measurements are **numeric**
		valueType - required, values xsd:type in turtle syntax
			    (e.g. valueType='^^int')
		unit - optional, URI to a Unit Ontology type, or a string
		context - optional, URI of the named graph for n-quads
 Description:   Creates the following structure:
 
                   node
                      has_measurement_value
                             sio:measurement_value(attributeID or bnode)
                                     has_value value
                                     [has_unit  unit]


=cut


sub addMeasurement {
	my ($self, %args) = @_;
	
	my $model = $args{model};
	
	my $subject = $args{node};  # subject
	my $attr_uri = $args{attributeID}; # object -> will become a _bnode if not specified
	my $val = $args{value};  # some numerical or string value
	my $unit = $args{unit};    # the unit of measure if numerical value
	my $attribute_type = SIO_MEASUREMENT_VALUE;  # specification of what "type" of object we have
	my $value_type = $args{valueType};  # specification of what "type" of value we have string, non-string, or OWL class
	my $pred = SIO_HAS_MEASUREMENT_VALUE;   # what is the predicate connecting this attribute to the subject node?
	my $context = $args{context};

	unless ($value_type =~ /^\^\^/){
		$self->error_message("SIO only allows ^^int, ^^float, or ^^double as the types of values for measurements.");
		return 0;
		
	}
	
	unless ($val) {
		$self->error_message("Measurements must have values...");
		return 0;

	}
	my $return = $self->addAttribute(
		model => $model,
		node => $subject,
		attributeID => $attr_uri,
		value => $val,
		unit => $unit,
		attributeType => $attribute_type,
		valueType => $value_type,
		predicate => $pred,
		context => $context,
	);
	
	return $return;
	
}



=head2 getAttributeTypes

 Usage     :	$SIO->getAttributeTypes(%args);
 Function  :    Retrieve a list of attribute types for a given node
 Returns   :	listref of matching RDF::Trine::Nodes,
                or listref of [0] on error (see $SIO->error_message)
 Args      :    model - an RDF::Trine::Model with the graph of interest
		node  - the RDF::Trine::Node to query attributes of
		as_string - if set to 'true', the routine will return a
		            listref of string URIs, instead of Trine nodes.
			      
		All arguments are required.


=cut



sub getAttributeTypes {
	my ($self, %args) = @_;
	my $model = $args{model};	
	my $subject = $args{node};  # subject
	my $asString = $args{as_string};
	
	my @all_types;
	
	my $hasAttr = $self->Trine->iri(SIO_HAS_ATTR);
	my $rdfType = $self->Trine->iri(RDF_TYPE);
	
	my $iterator = $model->get_statements ($subject, $hasAttr, undef);
	my @statements = $iterator->get_all;
	foreach my $statement(@statements){
		my $obj = $statement->object;
		my $it = $model->get_statements($obj, $rdfType, undef);
		my @types = $it->get_all;
		if ($asString){
			push @all_types, map {$_->object->as_string} @types;
		} else {
			push @all_types, map {$_->object} @types;
		}
		
	}

	return \@all_types;
	
}



=head2 getAttributesByType

 Usage     :	$SIO->getAttributesByType(%args);
 Function  :    You specify the rdf:type of the attribute you want
                and this routine retrieves all such SIO:attribute nodes
		from the node you submit.
 Returns   :	listref of matching RDF::Trine::Nodes,
                or listref of [0] on error (see $SIO->error_message)
 Args      :    model - an RDF::Trine::Model with the graph of interest
		node  - the RDF::Trine::Node to query attributes of
                attributeType - the URI of your attribute-type of interest
			      
		All arguments are required.


=cut


sub getAttributesByType {
	my ($self, %args) = @_;
	my $model = $args{model};	
	my $subject = $args{node};  # subject
	my $attribute_type = $args{attributeType};  # specification of what "type" of object we have

	unless ($model && $subject && $attribute_type) {
		$self->error_message("all arguments - model, nodem, and attributeType - are required");
		return [0];

	}

	my $attributeType = $self->Trine->iri($attribute_type);  # make type a Trine
	my $hasAttr = $self->Trine->iri(SIO_HAS_ATTR);
	my $rdfType = $self->Trine->iri(RDF_TYPE);
	
	my $iterator = $model->get_statements ($subject, $hasAttr, undef);
	my @statements = $iterator->get_all;

	my @matching_attributes;
	foreach my $statement(@statements){
		my $obj = $statement->object;
		my $it = $model->get_statements($obj, $rdfType, $attributeType);
		my @types = $it->get_all;
		if ($types[0]){push @matching_attributes, $obj }
		
	}
	return \@matching_attributes;
}




=head2 getUnitValue

 Usage     :	$SIO->getUnitValue(%args);
 Function  :    You provide an SIO attribute node and this routine
                retrieves the value and unit of that node (if available)
 Returns   :	list containing (Value, Unit) as scalars (note that if Unit is
                a reference to an ontology node, it will return the URI
		of that node, NOT the node as a Trine).  If there is no unit,
		undef will be returned as the second value of the list.
		Returns an empty list on failure.  
 Args      :    model - an RDF::Trine::Model with the graph of interest
		node  - the RDF::Trine::Node to query value/unit of
		
 Description:   The routine assumes that your graph has the following
                SIO-compliant structure:
		
		SIO:attribute
			--has_value--> Value(literal)
			--has_unit---> Unit (literal or URI node)
			
		Note that the routine assumes (as per my understanding of
		SIO) that only one value and one unit are allowed
		for any given attribute, so even if there is more than
		one, only one value/unit will returned!


=cut


sub getUnitValue {
	my ($self, %args) = @_;
	my $model = $args{model};	
	my $subject = $args{node};  # subject
	my $hasUnit = $self->Trine->iri(SIO_HAS_UNIT);  
	my $hasValue = $self->Trine->iri(SIO_HAS_VALUE);  

	unless ($model && $subject) {
		$self->error_message("all arguments - model, node - are required");
		return ();

	}

	my $iterator = $model->get_statements ($subject, $hasValue, undef);
	my @statements = $iterator->get_all;
	my $statement = shift @statements;
	unless ($statement) {
		$self->error_message("no value node was found");
		return ();

	}
	my $value = $statement->object->value;


	$iterator = $model->get_statements ($subject, $hasUnit, undef);
	@statements = $iterator->get_all;
	$statement = shift @statements;
	my $unit;
	if ($statement) {
		$unit = $statement->object->value;
	}
	return ($value, $unit);
}


=head2 getAttributeMeasurements

 Usage     :	$SIO->getAttributeMeasurements(%args);
 Function  :    a short-cut to retrieve SIO-style attribute measurements.
                (see Description for expected graph structure)
                retrieves value/unit pairs for each measurement of an attribute
 Returns   :	nested listref [[value, unit], [value, unit],...]
                for the precise details of the inner listrefs,
		see 'getUnitValue' documentation
 Args      :    model - an RDF::Trine::Model with the graph of interest
		node  - the RDF::Trine::Node to query attributes of
		        (would be SIO:thing in the diagram below)
		attributeType - URI of type of attribute you want the
		                measurement values for
				(e.g. http://myontology.org/SomeAttributeType)
		
 Description:   The routine assumes that your graph has the following
                SIO-compliant structure:
		
		SIO:thing
		  --has_attribute--> SIO:attribute
		     --rdf:type--> your:SomeAttributeType
		     --has_measurement_value--> SIO:measurement
			   --has_value--> Value(literal)
			   --has_unit---> Unit (literal or URI node)
			
		Note that the routine assumes (as per my understanding of
		SIO) that only one value and one unit are allowed
		for any given SIO:measurement, so even if there is more than
		one, only one value/unit will returned!
		
		this subroutine is ~equivalent to:
		getAttributesByType(SomeAttributeType)
		getAttributesByType(SIO:measurement)
		getUnitValue()


=cut



sub getAttributeMeasurements{
	my ($self, %args) = @_;
	my $model = $args{model};	
	my $subject = $args{node};  # subject
	my $attributeType = $args{attributeType};

	my @response;
	
	my $attributes = $self->getAttributesByType(
				  model => $model,
				  node => $subject,
				  attributeType => $attributeType
				  );
	my $hasMeasurementValue = $self->Trine->iri(SIO_HAS_MEASUREMENT_VALUE);
	
	foreach my $attribute(@$attributes){
		my $iterator = $model->get_statements ($attribute, $hasMeasurementValue, undef);
		my @statements = $iterator->get_all;
		foreach my $statement(@statements){
			my $measurement = $statement->object;
			my ($value, $unit) = $self->getUnitValue(node => $measurement,  model => $model,);
			push @response, [$value, $unit];
		}
		
	}
	return \@response;
}


sub _addStatementsToModel {
	my ($model, $statements) = @_;
	map {$model->add_statement($_)} @{$statements};
}

sub _updateModel{
	my ($T, $model, $subject, $predicate, $attribute, $classType, $value, $unit, $context ) = @_;
	my $rdfType = $T->iri(RDF_TYPE);
	my $SIO_ATTR = $T->iri(SIO_ATTRIBUTE);
	my $hasUnit = $T->iri(SIO_HAS_UNIT);
	my $hasValue = $T->iri(SIO_HAS_VALUE);
	my $hasAttr = $T->iri(SIO_HAS_ATTR);  # don't know if we should put this on also... for those without reasoners??

	my @statements;

	if ($context){
		push @statements, RDF::Trine::Statement::Quad->new($subject, $predicate, $attribute, $context);
	} else {
		push @statements, $T->statement($subject, $predicate, $attribute);
	}
	
	unless ( $predicate->equal($hasAttr) ){
		if ($context){
			push @statements, RDF::Trine::Statement::Quad->new($subject, $hasAttr, $attribute, $context);
		} else {
			push @statements, $T->statement($subject, $hasAttr, $attribute);		
		}
	}
	if ($context){
		push @statements, RDF::Trine::Statement::Quad->new($attribute, $rdfType, $classType, $context);
		push @statements, RDF::Trine::Statement::Quad->new($attribute, $rdfType, $SIO_ATTR, $context);	
	} else {
		push @statements, $T->statement($attribute, $rdfType, $classType);
		push @statements, $T->statement($attribute, $rdfType, $SIO_ATTR);
	}

	if ($value){
		if ($context){
			push @statements, RDF::Trine::Statement::Quad->new($attribute, $hasValue, $value, $context);
		} else {
			push @statements, $T->statement($attribute, $hasValue, $value);
		}
	}
	
	if ($unit){
		if ($context){
			push @statements, RDF::Trine::Statement::Quad->new($attribute, $hasUnit, $unit, $context);
		}else {
			push @statements, $T->statement($attribute, $hasUnit, $unit);
		}
	}

	&_addStatementsToModel($model, \@statements);

}


sub AUTOLOAD {

  no strict "refs";
  my ( $self, $newval ) = @_;
  $AUTOLOAD =~ /.*::(\w+)/;
  my $attr = $1;
  if ( $self->_accessible( $attr, 'write' ) ) {
    *{$AUTOLOAD} = sub {
      if ( defined $_[1] ) { $_[0]->{$attr} = $_[1]; }
      return $_[0]->{$attr};
    };    ### end of created subroutine
    ###  this is called first time only
    if ( defined $newval ) {
      $self->{$attr} = $newval;
    }
    return $self->{$attr};
  } elsif ( $self->_accessible( $attr, 'read' ) ) {
    *{$AUTOLOAD} = sub {
      return $_[0]->{$attr};
    };    ### end of created subroutine
    return $self->{$attr};
  }
  
  # Must have been a mistake then...
  croak "No such method: $AUTOLOAD";
}
sub DESTROY { }
1;