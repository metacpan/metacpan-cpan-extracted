package Net::RRP::Exception::InvalidCommandOption;

$Net::RRP::Exception::InvalidCommandOption::VERSION = '0.02';
@Net::RRP::Exception::InvalidCommandOption::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 501,
			 -text  => 'Invalid command option' );
}

1;
