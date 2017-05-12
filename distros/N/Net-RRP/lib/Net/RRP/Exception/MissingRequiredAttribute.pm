package Net::RRP::Exception::MissingRequiredAttribute;

$Net::RRP::Exception::MissingRequiredAttribute::VERSION = '0.02';
@Net::RRP::Exception::MissingRequiredAttribute::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 504,
			 -text  => "Missing required attribute" );
}

1;
