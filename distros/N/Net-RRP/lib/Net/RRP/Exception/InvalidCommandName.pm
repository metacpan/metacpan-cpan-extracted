package Net::RRP::Exception::InvalidCommandName;

$Net::RRP::Exception::InvalidCommandName::VERSION = '0.02';
@Net::RRP::Exception::InvalidCommandName::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -text  => 'Invalid command name',
			 -value => 500 );
}

1;

