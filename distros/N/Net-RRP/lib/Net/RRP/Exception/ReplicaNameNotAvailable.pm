package Net::RRP::Exception::ReplicaNameNotAvailable;

$Net::RRP::Exception::ReplicaNameNotAvailable::VERSION = '0.03';
@Net::RRP::Exception::ReplicaNameNotAvailable::ISA     = qw ( Net::RRP::Exception::EntityNotAvailable );

use strict;
use Net::RRP::Exception::EntityNotAvailable;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 10002,
			 -text  => 'Replica name is not available' );
}

1;
