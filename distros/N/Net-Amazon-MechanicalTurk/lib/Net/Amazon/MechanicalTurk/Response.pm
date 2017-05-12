package Net::Amazon::MechanicalTurk::Response;

use strict;
use warnings;
use Net::Amazon::MechanicalTurk::BaseObject;
use Net::Amazon::MechanicalTurk::XMLParser;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };
our %CLIENT_ERRORS = (
    "TransportError"      => "There was an error communicating with MechanicalTurk.",
    "ResponseFormatError" => "Could not find response in XML received from MechanicalTurk.",
    "MalformedXML"        => "Invald XML received from MechanicalTurk.",
    "UnknownError"        => "An unknown error was received from MechanicalTurk."
);

Net::Amazon::MechanicalTurk::Response->attributes(qw{
    errorMessage
    errorCode
    fullResult
    result
    type
});

sub init {
    my $self = shift;
    $self->setAttributes(@_);
}

sub xml {
    my $self = shift;
    my $attrName = "Net::Amazon::MechanicalTurk::Response::xml";
    if ($#_ >= 0) {
        my $xml = shift;
        $self->{$attrName} = $xml;
        $self->parseResult();
    }
    return $self->{$attrName};
}

sub clientError {
    my ($self, $type, $message) = @_;

    if (!exists $CLIENT_ERRORS{$type}) {
        die "Unknown error type $type.";
    }

    if (defined($message)) {
        $message = $CLIENT_ERRORS{$type} . " " . $message;
    }
    else { 
        $message = $CLIENT_ERRORS{$type};
    }

    $self->errorCode("Client.${type}");
    $self->errorMessage($message);

    if (!$self->type) {
        $self->type('ClientError');
    }

    return $self;
}

sub parseResult {
    my ($self) = @_;

    $self->debugMessage("Parsing XML response.");
    
    $self->fullResult(undef);
    $self->result(undef);
    $self->errorCode(undef);
    $self->errorMessage(undef);
    $self->type(undef);

    # Parse the XML
    my ($fullResult, $rootElement);
    eval {
        ($fullResult, $rootElement) = Net::Amazon::MechanicalTurk::XMLParser->new->parse($self->xml);
        $self->debugMessage("Parsed XML.");
    };
    if ($@) {
        $self->debugMessage("Error: $@");
        $self->clientError('MalformedXML');
        return;
    }

    $self->type($rootElement);
    $self->fullResult($fullResult);

    my $error;
    $self->fullResult->visit(sub {
        my ($key, $value, $nodes) = @_;
        if (!defined($error) and defined($key) and $key eq "Error") {
            $error = $value->get(1);
        }
    });
    if (defined($error)) {
        $self->errorCode($error->getFirst("Code"));
        $self->errorMessage($error->getFirst("Message"));
        if (!$self->errorCode) {
            $self->clientError('UnknownError');
        }
        elsif (!$self->errorMessage) {
            $self->errorMessage();
        }
    }
    else {
        my $result;
        while (my ($key,$value) = each %{$self->fullResult}) {
            if (!defined($result) and $key ne "OperationRequest") {
                if (UNIVERSAL::isa($value, "ARRAY")) {
                    if ($#{$value} == 0) {
                        $result = $value->[0];
                    }
                    else {
                        $result = $value;
                    }
                }
            }
        }
        
        if (!defined($result)) {
            $self->clientError("ResponseFormatError");
        }
        
        $self->result($result);
    }
}

sub toString {
    my $self = shift;
    my $str = sprintf "<<%s>>", ref($self);
    $str .= "\n  Type: " . $self->type;
    if ($self->errorCode) {
        $str .= "\n  Error Code: " . $self->errorCode;
        $str .= "\n  Error Message: " . $self->errorMessage;
    }
    if (defined($self->fullResult)) {
        $str .= "\n  Result: \n";
        foreach my $line (split /\n/, $self->fullResult->toString) {
            $str .= "    $line\n";
        }
    }
    return $str;
}

return 1;
