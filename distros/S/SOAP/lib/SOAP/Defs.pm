package SOAP::Defs;
$VERSION = '0.28';
use vars(qw($VERSION));
require Exporter;
@ISA = qw(Exporter);

#
# Strings from the SOAP spec
#
$soap_namespace           = 'http://schemas.xmlsoap.org/soap/envelope/';
$soap_prefix              = 's'; # purposely avoid SOAP-ENV during development
$soap_encoding_style      = 'encodingStyle';
$soap_section5_encoding   = 'http://schemas.xmlsoap.org/soap/encoding/';
$soap_envelope            = 'Envelope';
$soap_body                = 'Body';
$soap_header              = 'Header';
$soap_package             = 'Package';
$soap_id                  = 'id';
$soap_href                = 'href';
$soap_must_understand     = 'mustUnderstand';
$soap_root_with_id        = 'root';
$soap_true                = '1';
$soap_false               = '0';
$soap_fc_version_mismatch = 'VersionMismatch';
$soap_fc_must_understand  = 'MustUnderstand';
$soap_fc_client           = 'Client';
$soap_fc_server           = 'Server';


#
# Strings from the XML Schema spec
#
$xsd_namespace     = 'http://www.w3.org/1999/XMLSchema';
$xsi_namespace     = 'http://www.w3.org/1999/XMLSchema-instance';
$xsd_prefix        = 'xsd';
$xsi_prefix        = 'xsi';
$xsd_null          = 'null';
$xsd_type          = 'type';
$xsd_string        = 'string';

#
# SOAP/Perl implementation specific constants
#
$soapperl_intrusive_hash_key_typeuri    = 'soap_typeuri';
$soapperl_intrusive_hash_key_typename   = 'soap_typename';

my @soap_spec_strings =
    qw( $soap_namespace
	$soap_prefix
        $soap_encoding_style
        $soap_section5_encoding
        $soap_envelope
        $soap_body
        $soap_header
        $soap_package
        $soap_id
        $soap_href
        $soap_must_understand
        $soap_root_with_id
        $soap_true
        $soap_false
	$soap_fc_version_mismatch
	$soap_fc_must_understand
	$soap_fc_client
	$soap_fc_server
        );

my @xsd_spec_strings =
    qw( $xsd_namespace
	$xsi_namespace
	$xsd_prefix
	$xsi_prefix
        $xsd_type
        $xsd_null
        $xsd_string
        );

my @soapperl_constants =
    qw( $soapperl_accessor_type_simple
        $soapperl_accessor_type_compound
        $soapperl_accessor_type_array
        $soapperl_intrusive_hash_key_typeuri
        $soapperl_intrusive_hash_key_typename
        );

@EXPORT =
    ( @soap_spec_strings,
      @xsd_spec_strings,
      @soapperl_constants,
    );

1;

__END__

=head1 NAME

SOAP::Defs - Spec-defined constants

=head1 SYNOPSIS

    use SOAP::Defs;

=head1 DESCRIPTION

This is an internal class that exports global symbols needed
by various SOAP/Perl classes. You don't need to import this module
directly unless you happen to be building SOAP plumbing (as opposed
to simply writing a SOAP client or server).

=head1 AUTHOR

Keith Brown

=cut
