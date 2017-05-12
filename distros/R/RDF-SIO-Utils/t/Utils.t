# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

# Note added by Frank Gibbons.
# Tests should, as far as possible, avoid the use of literals.
# If you register a service with authURI => mysite.com,
# and you want to test a retrieved description of the service,
# don't test that the service returns authURI eq "mysite.com",
# test so that it returns the same value as you used to register it in the first place.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
#use SOAP::Lite +trace;
use Test::More 'no_plan'; # perldoc Test::More for details
use lib "../lib";
use strict;
use English;
use Data::Dumper;
use RDF::SIO::Utils;
#Is the client-code even installed?
BEGIN { use_ok('RDF::SIO::Utils') };
 
END {
  # Clean up after yourself, in case tests fail, or the interpreter is interrupted partway though...
};


my $SIO = RDF::SIO::Utils->new();

is ($SIO->error_message, undef, "SIO does not have an error message");
isa_ok ($SIO->Trine, 'RDF::SIO::Utils::Trine',  "Trine was not created properly");

 
 # auto created RDF::Utils::Trine is there
 # use it to create a temporary model
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
isa_ok ($BloodPressure, 'RDF::Trine::Node', $SIO->error_message);

my ($value, $unit) = (115, "mmHg");

my $Measurement = $SIO->addMeasurement(model => $m,
                   node => $BloodPressure,
                   attributeID => "http://mydatastore.org/observation1",
                   value => $value,
                   valueType => "^^int",
                   unit => $unit
                   );

isa_ok ($Measurement,  'RDF::Trine::Node', $SIO->error_message);
my ($val, $un) = $SIO->getUnitValue(model => $m, node => $Measurement);
is ($val, $value, "values coming out dont match");
is ($un, $unit, "units coming out don't match");

    

 my $types = $SIO->getAttributeTypes(
        model => $m,
        node => $s);

my $num_attr = scalar(@$types);
is ($num_attr, 2, "wrong number of attributes found in model by getAttributeTypes");

 my $bp = $SIO->getAttributesByType(
        model =>$m,
        node => $s,
        attributeType =>"http://myontology.org/class/BloodPressure",  );

$num_attr = scalar(@$bp);
is ($num_attr, 1, "wrong number of attributes found in model getting Attributes by type");

my $data = $SIO->getAttributeMeasurements(
    model => $m,
    node => $s,
    attributeType => "http://myontology.org/class/BloodPressure"
    );

$num_attr = scalar(@$data);
is ($num_attr, 1, "wrong number of attributes found in model getting Attributes by type");

 
foreach my $data_point(@$data){    
    my ($val, $un) = ("", "");
    ($val, $un) = @$data_point;
    is ($val, $value, "values coming out dont match when getting Attribute Measurements");
    is ($un, $unit, "units coming out don't match when getting Attribute Measurements");
 }
 
