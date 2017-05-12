package Net::RRP::Exception::ContactNameNotAvailable;

$Net::RRP::Exception::ContactNameNotAvailable::VERSION = '0.03';
@Net::RRP::Exception::ContactNameNotAvailable::ISA     = qw ( Net::RRP::Exception::EntityNotAvailable );

use strict;
use Net::RRP::Exception::EntityNotAvailable;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 10003,
			 -text  => 'Contact name is not available' );
}

1;
