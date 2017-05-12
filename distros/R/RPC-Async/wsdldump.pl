#!/usr/bin/env perl
use strict;
use warnings;

use RPC::Async::Client;
use IO::EventMux;

# Run with ./wsdldump.pl | xmlindent

my $target_namespace = 'http://soap.netlookup.dk/test'; 
#
# FIXME: http://msdn2.microsoft.com/en-us/library/ms996486.aspx#understand_topic2

my %types = (
    integer8   => 'byte',
    integer16  => 'short',
    integer32  => 'int',
    integer64  => 'long',
    float32    => 'float',
    float64    => 'double',
    uinteger8  => 'unsignedByte',
    uinteger16 => 'unsignedShort',
    uinteger32 => 'unsignedInt',
    uinteger64 => 'unsignedLong',
    boolean    => 'boolean',
    utf8string => 'string',
);


my $wsdl_header = 
qq{<?xml version="1.0" encoding="utf-8"?>
<wsdl:definitions name="netlookup"
        targetNamespace="$target_namespace"
        xmlns:tns="$target_namespace"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
        xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
        xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"
        xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
        xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/"
        xmlns="http://schemas.xmlsoap.org/wsdl/">
};

my $wsdl_footer = qq{</wsdl:definitions>\n};

my $types_header =
qq{<wsdl:types>
<xsd:schema elementFormDefault="qualified" targetNamespace="$target_namespace">
};

my $types_footer =
qq{</xsd:schema>
</wsdl:types>
};

my $complex_start = 
qq{<xsd:complexType>
<xsd:sequence>
};
my $complex_end = 
qq{</xsd:sequence>
</xsd:complexType>
};

my $end = "/>\n";

my $element_start = qq{<xsd:element minOccurs="0" maxOccurs="1"};

my $mux = IO::EventMux->new();

# Set the user for the server to run under.
$ENV{'IO_URL_USER'} ||= 'root';

my $rpc = RPC::Async::Client->new($mux, "perl://./test-server.pl") or die;

$rpc->methods(defs => 1, sub {
    my (%ans) = @_;
    my $proxy = "testd";
    my $location = "http://localhost:1981/soap";
    my $method = "sum";

    my $types = '';
    my $messages = 
        qq{<wsdl:message name="${method}_input">\n}.
        qq{<wsdl:part name="parameters" element="tns:${method}_input"/>\n}.
        qq{</wsdl:message>\n}.
        qq{<wsdl:message name="${method}_output">\n}.
        qq{<wsdl:part name="parameters" element="tns:${method}_output"/>\n}.
        qq{</wsdl:message>\n};
   
    my $porttypes = 
        qq{<wsdl:portType name="${proxy}_interface">\n}.
        qq{<wsdl:operation name="${method}">\n}.
        qq{<wsdl:input message="tns:${method}_input"/>\n}.
        qq{<wsdl:output message="tns:${method}_output"/>\n}.
        qq{</wsdl:operation>\n}.
        qq{</wsdl:portType>\n};

    my $bindings =
        qq{<wsdl:binding name="${proxy}_bindings" type="tns:${proxy}_interface">\n}.
        qq{<soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>\n}.
        qq{<wsdl:operation name="$method">\n}.
        qq{<soap:operation soapAction="$target_namespace/$method" style="document"/>\n}.
        qq{<wsdl:input name="${method}_input">\n}.
        qq{<soap:body use="literal"/>\n}.
        qq{</wsdl:input>\n}.
        qq{<wsdl:output name="${method}_output">\n}.
        qq{<soap:body use="literal"/>\n}.
        qq{</wsdl:output>\n}.
        qq{</wsdl:operation>\n}.
        qq{</wsdl:binding>\n};
    
    my $services =
        qq{<wsdl:service name="${proxy}_service">}.
        qq{<wsdl:port name="${proxy}_soap" binding="tns:${proxy}_bindings">}.
        qq{<soap:address location="$location"/>}.
        qq{</wsdl:port>}.
        qq{</wsdl:service>};

    $types .= $types_header;
    $types .= qq{<xsd:element name="${method}_input">\n};
    foreach my $parmname (sort keys %{$ans{methods}{$method}{in}}) {
        my $type = $ans{methods}{$method}{in}{$parmname}; 

        if(ref $type eq '') {
            $type = ($types{$type} or die "Unknown type: $type");
            $types .= "$complex_start";
            $types .= qq{$element_start name="$parmname" type="xsd:$type"$end};
            $types .= "$complex_end";
        
        } elsif(ref $type eq 'ARRAY') {

        } elsif(ref $type eq 'HASH') {

        }
    }
    $types .= qq{</xsd:element>\n};
    
    $types .= qq{<xsd:element name="${method}_output">\n};
    foreach my $parmname (sort keys %{$ans{methods}{$method}{out}}) {
        my $type = $ans{methods}{$method}{out}{$parmname}; 
        
        # FIXME: Make hash map for looking up wsdl types to map to.
        # This parameter map directly to a soap base type
        if(ref $type eq '') {
            $type = ($types{$type} or die "Unknown type: $type");
            $types .= "$complex_start";
            $types .= qq{$element_start name="$parmname" type="xsd:$type"$end};
            $types .= "$complex_end";
        }
    }
    $types .= qq{</xsd:element>\n};
    $types .= $types_footer;
    
    print "$wsdl_header".
        "$types$messages$porttypes$bindings$services".
        "$wsdl_footer";

#    use Data::Dumper;
#    print Dumper($ans{methods}{add_numbers});
#    print Dumper(\%ans);
    #is(, 'integer32:pos', 
    #    "Check that rpc_get_id was converted");
});

while ($rpc->has_requests) {
    my $event = $mux->mux;
    $rpc->io($event);
}

$rpc->disconnect;
