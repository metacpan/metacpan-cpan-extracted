package Net::RRP::Exception::DomainNameNotAvailable;

$Net::RRP::Exception::DomainNameNotAvailable::VERSION = '0.02';
@Net::RRP::Exception::DomainNameNotAvailable::ISA     = qw ( Net::RRP::Exception::EntityNotAvailable );

use strict;
use Net::RRP::Exception::EntityNotAvailable;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 211,
			 -text  => 'Domain name is not available' );
}

1;
