package Net::RRP::Exception::InvalidOptionValue;

$Net::RRP::Exception::InvalidOptionValue::VERSION = '0.02';
@Net::RRP::Exception::InvalidOptionValue::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 506,
			 -text  => 'Invalid option value' );
}

1;
