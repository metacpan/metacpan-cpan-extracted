package Net::RRP::Exception::ServerError;

$Net::RRP::Exception::ServerError::VERSION = '0.02';
@Net::RRP::Exception::ServerError::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 420,
			 -text  => 'Command failed due to server error' );
}

1;

