package Net::RRP::Exception::OwnershipFailed;

$Net::RRP::Exception::OwnershipFailed::VERSION = '0.02';
@Net::RRP::Exception::OwnershipFailed::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 531,
			 -text  => 'Authorization failed' );
}

1;
