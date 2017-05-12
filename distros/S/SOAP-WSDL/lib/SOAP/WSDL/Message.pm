package SOAP::WSDL::Message;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use base qw(SOAP::WSDL::Base);

our $VERSION = 3.003;

my %part_of :ATTR(:name<part> :default<[]>);

1;
