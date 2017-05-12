package Net::RRP::Exception::InvalidAttributeName;

$Net::RRP::Exception::InvalidAttributeName::VERSION = '0.02';
@Net::RRP::Exception::InvalidAttributeName::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 503,
			 -text  => 'Invalid attribute name' );
}

1;
