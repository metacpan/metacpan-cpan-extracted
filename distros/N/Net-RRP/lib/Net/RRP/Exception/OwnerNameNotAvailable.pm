package Net::RRP::Exception::OwnerNameNotAvailable;

$Net::RRP::Exception::OwnerNameNotAvailable::VERSION = '0.03';
@Net::RRP::Exception::OwnerNameNotAvailable::ISA     = qw ( Net::RRP::Exception::EntityNotAvailable );

use strict;
use Net::RRP::Exception::EntityNotAvailable;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 10004,
			 -text  => 'Owner name is not available' );
}

1;
