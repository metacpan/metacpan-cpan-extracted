package Net::DashCS::Types::location;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(0);

sub get_xmlns { 'http://dashcs.com/api/v1/emergency' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %activatedtime_of :ATTR(:get<activatedtime>);
my %address1_of :ATTR(:get<address1>);
my %address2_of :ATTR(:get<address2>);
my %callername_of :ATTR(:get<callername>);
my %comments_of :ATTR(:get<comments>);
my %community_of :ATTR(:get<community>);
my %customerorderid_of :ATTR(:get<customerorderid>);
my %latitude_of :ATTR(:get<latitude>);
my %legacydata_of :ATTR(:get<legacydata>);
my %locationid_of :ATTR(:get<locationid>);
my %longitude_of :ATTR(:get<longitude>);
my %plusfour_of :ATTR(:get<plusfour>);
my %postalcode_of :ATTR(:get<postalcode>);
my %state_of :ATTR(:get<state>);
my %status_of :ATTR(:get<status>);
my %type_of :ATTR(:get<type>);
my %updatetime_of :ATTR(:get<updatetime>);

__PACKAGE__->_factory(
    [ qw(        activatedtime
        address1
        address2
        callername
        comments
        community
        customerorderid
        latitude
        legacydata
        locationid
        longitude
        plusfour
        postalcode
        state
        status
        type
        updatetime

    ) ],
    {
        'activatedtime' => \%activatedtime_of,
        'address1' => \%address1_of,
        'address2' => \%address2_of,
        'callername' => \%callername_of,
        'comments' => \%comments_of,
        'community' => \%community_of,
        'customerorderid' => \%customerorderid_of,
        'latitude' => \%latitude_of,
        'legacydata' => \%legacydata_of,
        'locationid' => \%locationid_of,
        'longitude' => \%longitude_of,
        'plusfour' => \%plusfour_of,
        'postalcode' => \%postalcode_of,
        'state' => \%state_of,
        'status' => \%status_of,
        'type' => \%type_of,
        'updatetime' => \%updatetime_of,
    },
    {
        'activatedtime' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
        'address1' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'address2' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'callername' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'comments' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'community' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'customerorderid' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'latitude' => 'SOAP::WSDL::XSD::Typelib::Builtin::double',
        'legacydata' => 'Net::DashCS::Types::legacyLocationData',
        'locationid' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'longitude' => 'SOAP::WSDL::XSD::Typelib::Builtin::double',
        'plusfour' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'postalcode' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'state' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'status' => 'Net::DashCS::Types::locationStatus',
        'type' => 'Net::DashCS::Types::locationType',
        'updatetime' => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
    },
    {

        'activatedtime' => 'activatedtime',
        'address1' => 'address1',
        'address2' => 'address2',
        'callername' => 'callername',
        'comments' => 'comments',
        'community' => 'community',
        'customerorderid' => 'customerorderid',
        'latitude' => 'latitude',
        'legacydata' => 'legacydata',
        'locationid' => 'locationid',
        'longitude' => 'longitude',
        'plusfour' => 'plusfour',
        'postalcode' => 'postalcode',
        'state' => 'state',
        'status' => 'status',
        'type' => 'type',
        'updatetime' => 'updatetime',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Net::DashCS::Types::location

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
location from the namespace http://dashcs.com/api/v1/emergency.






=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * activatedtime


=item * address1


=item * address2


=item * callername


=item * comments


=item * community


=item * customerorderid


=item * latitude


=item * legacydata


=item * locationid


=item * longitude


=item * plusfour


=item * postalcode


=item * state


=item * status


=item * type


=item * updatetime




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Net::DashCS::Types::location
   activatedtime =>  $some_value, # dateTime
   address1 =>  $some_value, # string
   address2 =>  $some_value, # string
   callername =>  $some_value, # string
   comments =>  $some_value, # string
   community =>  $some_value, # string
   customerorderid =>  $some_value, # string
   latitude =>  $some_value, # double
   legacydata =>  { # Net::DashCS::Types::legacyLocationData
     housenumber =>  $some_value, # string
     predirectional =>  $some_value, # string
     streetname =>  $some_value, # string
     suite =>  $some_value, # string
   },
   locationid =>  $some_value, # string
   longitude =>  $some_value, # double
   plusfour =>  $some_value, # string
   postalcode =>  $some_value, # string
   state =>  $some_value, # string
   status =>  { # Net::DashCS::Types::locationStatus
     code => $some_value, # locationStatusCode
     description =>  $some_value, # string
   },
   type => $some_value, # locationType
   updatetime =>  $some_value, # dateTime
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

