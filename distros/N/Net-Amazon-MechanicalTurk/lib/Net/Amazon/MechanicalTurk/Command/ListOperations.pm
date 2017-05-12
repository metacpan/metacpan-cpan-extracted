package Net::Amazon::MechanicalTurk::Command::ListOperations;
use strict;
use warnings;

our $VERSION = '1.00';

=head1 NAME

Net::Amazon::MechanicalTurk::Command::ListOperations - Lists MechanicalTurk
requester operations.

Returns a list of method names that may be called against the requester API.

This method parses the WSDL used for the MechanicalTurk soap endpoint.
This method may fail while attempting to download the WSDL document.

=head1 SYNOPSIS

    print "Methods for web service version: ", $mturk->serviceVersion, "\n";
    foreach my $operation ($mturk->listOperations) {
        print $operation, "\n";
    }

=cut 

sub listOperations {
    my $mturk = shift;
    my $wsdlUrl = shift;
    if (!defined($wsdlUrl)) {
        $wsdlUrl = "https://mechanicalturk.amazonaws.com/AWSMechanicalTurk/" . $mturk->serviceVersion . "/AWSMechanicalTurkRequester.wsdl";
    }
    my $parser = Net::Amazon::MechanicalTurk::XMLParser->new;
    my $wsdl = $parser->parseURL($wsdlUrl);
    my @operationNames;
    my $operations = $wsdl->{binding}[0]{operation};
    foreach my $operation (@$operations) {
        push(@operationNames, $operation->{name}[0]);
    }
    return sort(@operationNames);
}

return 1;
