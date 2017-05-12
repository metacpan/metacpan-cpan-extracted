package Net::Ikano::XMLUtil;

use warnings;
use strict;
use base 'XML::Simple';
use Data::Dumper;
use Switch;

=head1 DESCRIPTION
    
Unfortunately the Ikano API schema has xs:sequence everywhere, so we need to have most elements in a particular order.
This class solves this problem by extending XML::Simple and overriding sorted_keys to provide the element order for each request.

This is a helper class which should not be used directly. It requires particular options in the constructor (SuppressEmpty) which differ for XMLin and XMLout.

=cut

sub sorted_keys {
    my ($self,$name,$hashref) = @_;

    switch ($name) { 

	# quals
	return qw( AddressLine1 AddressUnitType AddressUnitValue AddressCity
		    AddressState ZipCode Country LocationType ) case 'Address';
	return qw( Address PhoneNumber CheckNetworks RequestClientIP ) case 'PreQual';

	# orders
	return qw( type ProductCustomId DSLPhoneNumber VirtualPhoneNumber Password
	    TermsId PrequalId CompanyName FirstName MiddleName LastName
	    ContactMethod ContactPhoneNumber ContactEmail ContactFax DateToOrder
	    RequestClientIP IspChange IspPrevious CurrentProvider ) case 'Order';

	# password change
	return qw( DSLPhoneNumber NewPassword ) case 'PasswordChange';

	# account status change
	return qw( type DSLServiceId DSLPhoneNumber ) case 'AccountStatusChange';

    }
    return $self->SUPER::sorted_keys($name, $hashref);
}

1;
