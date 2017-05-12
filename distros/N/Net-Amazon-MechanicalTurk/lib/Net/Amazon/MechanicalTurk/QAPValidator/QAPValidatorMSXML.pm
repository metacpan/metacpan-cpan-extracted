package Net::Amazon::MechanicalTurk::QAPValidator::QAPValidatorMSXML;
use strict;
use warnings;
use Win32::OLE;
use Carp;
use Net::Amazon::MechanicalTurk::QAPValidator;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::QAPValidator };

our $MSXML_VERSION;

BEGIN {
    foreach my $version (qw{ 5.0 4.0 }) {
        my $dom;
        eval {
            $dom = Win32::OLE->new("MSXML2.DOMDocument.${version}");
        };
        if ($dom) {
            $MSXML_VERSION = $version;
            last;
        }
    }
    if (!$MSXML_VERSION) {
        die "Could not find a version of MSXML to use.";
    }
}

sub validate {
    my ($self, $xml, $info) = @_;
    
    my $dom = newDom();
    my $xsd = newDom();
    my $schemas = newSchemaCache();
    
    $dom->{Async} = 0;
    $xsd->{Async} = 0;
    if (!$xsd->LoadXML($self->questionFormXSD)) {
        Carp::croak("Could not load XSD - " . $xsd->parseError->{Reason});
    }
    $schemas->Add($self->questionFormNamespace, $xsd);
    $dom->{Schemas} = $schemas;
    $dom->{ValidateOnParse} = 1;
    
    if (!$dom->LoadXML($xml)) {
        my $error = $dom->parseError;
        $info->{line} = $error->{Line};
        $info->{column} = $error->{Linepos};
        $info->{message} = $error->{Reason};
        return 0;
    }
        
    return 1;
}

sub newDom {
    return newOLE("MSXML2.DOMDocument.$MSXML_VERSION");
}

sub newSchemaCache {
    return newOLE("MSXML2.XMLSchemaCache.$MSXML_VERSION");
}

sub newOLE {
    my ($progid) = @_;
    my $prog = Win32::OLE->new($progid);
    if (!$prog) {
        die "Couldn't create new $progid";
    }
    return $prog;
}

return 1;
