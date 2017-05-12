package SOAP::WSDL::Service;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use base qw(SOAP::WSDL::Base);

our $VERSION = 3.003;

my %port_of    :ATTR(:name<port>   :default<[]>);

1;
