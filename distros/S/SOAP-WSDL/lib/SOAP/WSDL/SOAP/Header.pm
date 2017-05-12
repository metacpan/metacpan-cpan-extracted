package SOAP::WSDL::SOAP::Header;
use strict;
use warnings;
use base qw(SOAP::WSDL::Base);
use Class::Std::Fast::Storable;

our $VERSION = 3.003;

my %use_of              :ATTR(:name<use>            :default<q{}>);
my %namespace_of        :ATTR(:name<namespace>      :default<q{}>);
my %encodingStyle_of    :ATTR(:name<encodingStyle>  :default<q{}>);
my %message_of          :ATTR(:name<message>        :default<()>);
my %part_of             :ATTR(:name<part>          :default<q{}>);


1;