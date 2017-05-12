package Net::RRP::Exception::RegistrarNameNotAvailable;

$Net::RRP::Exception::RegistrarNameNotAvailable::VERSION = '0.03';
@Net::RRP::Exception::RegistrarNameNotAvailable::ISA     = qw ( Net::RRP::Exception::EntityNotAvailable );

use strict;
use Net::RRP::Exception::EntityNotAvailable;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 10001,
			 -text  => 'Registrar name is not available' );
}

1;
