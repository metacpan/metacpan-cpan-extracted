
package Net::DashCS::Elements::provisionLocation;
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'http://dashcs.com/api/v1/emergency' }

__PACKAGE__->__set_name('provisionLocation');
__PACKAGE__->__set_nillable();
__PACKAGE__->__set_minOccurs();
__PACKAGE__->__set_maxOccurs();
__PACKAGE__->__set_ref();
use base qw(
    SOAP::WSDL::XSD::Typelib::Element
    Net::DashCS::Types::provisionLocation
);

}

1;


=pod

=head1 NAME

Net::DashCS::Elements::provisionLocation

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
provisionLocation from the namespace http://dashcs.com/api/v1/emergency.







=head1 METHODS

=head2 new

 my $element = Net::DashCS::Elements::provisionLocation->new($data);

Constructor. The following data structure may be passed to new():

 { # Net::DashCS::Types::provisionLocation
   locationid =>  $some_value, # string
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=cut

