package Net::RRP::Exception::MissingRequiredEntity;

$Net::RRP::Exception::MissingRequiredEntity::VERSION = '0.02';
@Net::RRP::Exception::MissingRequiredEntity::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 508,
			 -text  => 'Missing required entity' );
}

1;
