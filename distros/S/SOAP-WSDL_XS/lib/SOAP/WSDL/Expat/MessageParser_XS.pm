package SOAP::WSDL::Expat::MessageParser_XS;
use strict; use warnings;
require Class::Std::Fast::Storable;
require SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType;
require SOAP::WSDL::XSD::Typelib::ComplexType;
require DynaLoader;
use base qw(SOAP::WSDL::Expat::MessageParser DynaLoader);

bootstrap SOAP::WSDL::Expat::MessageParser_XS 0.2;

# Initialize:
# get object cache from Class::Std::Fast
# get global attribute ref from SOAP::WSDL::XSD::Typelib::ComplexType
SOAP::WSDL::Expat::MessageParser_XS::init(
    Class::Std::Fast::ID_GENERATOR_REF(),
    Class::Std::Fast::OBJECT_CACHE_REF()
);

sub parse_string {
    return $_[0]->{ data } = SOAP::WSDL::Expat::MessageParser_XS::_parse_string(
        $_[1],
        $_[0]->class_resolver->get_typemap(),
    );
}

sub get_data {
    return $_[0]->{ data };
}

sub get_header {}
1;
