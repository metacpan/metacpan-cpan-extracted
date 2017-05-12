package Net::RRP::Exception::InvalidCommandSequence;

$Net::RRP::Exception::InvalidCommandSequence::VERSION = '0.02';
@Net::RRP::Exception::InvalidCommandSequence::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 547,
			 -text  => 'Invalid command sequence' );
}

1;
