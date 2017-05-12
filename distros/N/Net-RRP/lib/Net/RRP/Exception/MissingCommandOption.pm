package Net::RRP::Exception::MissingCommandOption;

$Net::RRP::Exception::MissingCommandOption::VERSION = '0.02';
@Net::RRP::Exception::MissingCommandOption::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 509,
			 -text  => 'Missing command option' );
}

1;
