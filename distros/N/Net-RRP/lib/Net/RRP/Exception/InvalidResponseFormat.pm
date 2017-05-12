package Net::RRP::Exception::InvalidResponseFormat;

$Net::RRP::Exception::InvalidResponseFormat::VERSION = '0.02';
@Net::RRP::Exception::InvalidResponseFormat::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => -1,
			 -text  => 'Invalid response format' );
}

1;
