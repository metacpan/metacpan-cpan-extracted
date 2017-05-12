package Net::RRP::Exception::InvalidEntityValue;

$Net::RRP::Exception::InvalidEntityValue::VERSION = '0.02';
@Net::RRP::Exception::InvalidEntityValue::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 502,
			 -text  => 'Invalid entity value' );
}

1;
