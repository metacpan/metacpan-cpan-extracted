package SOAP::WSDL::XSD::Annotation;
use strict;
use warnings;
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::Base);

our $VERSION = 3.004;

#<enumeration value="">

# id provided by Base
# name provided by Base
# annotation provided by Base

# may be defined as atomic simpleType
my %appinfo_of        :ATTR(:name<appinfo> :default<()>);

# documentation provided by Base

1;