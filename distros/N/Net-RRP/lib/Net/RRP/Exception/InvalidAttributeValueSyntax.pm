package Net::RRP::Exception::InvalidAttributeValueSyntax;

$Net::RRP::Exception::InvalidAttributeValueSyntax::VERSION = '0.02';
@Net::RRP::Exception::InvalidAttributeValueSyntax::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 505,
			 -text  => 'Invalid attribute value syntax' );
}

1;
