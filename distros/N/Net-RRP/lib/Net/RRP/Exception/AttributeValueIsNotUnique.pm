package Net::RRP::Exception::AttributeValueIsNotUnique;

$Net::RRP::Exception::AttributeValueIsNotUnique::VERSION = '0.02';
@Net::RRP::Exception::AttributeValueIsNotUnique::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 540,
			 -text  => 'Attribute value is not unique' );
}

1;
