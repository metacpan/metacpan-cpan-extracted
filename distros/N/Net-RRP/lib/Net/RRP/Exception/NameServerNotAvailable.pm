package Net::RRP::Exception::NameServerNotAvailable;

$Net::RRP::Exception::NameServerNotAvailable::VERSION = '0.02';
@Net::RRP::Exception::NameServerNotAvailable::ISA     = qw ( Net::RRP::Exception::EntityNotAvailable );

use strict;
use Net::RRP::Exception::EntityNotAvailable;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 213,
			 -text  => 'Name server is not available' );
}

1;
