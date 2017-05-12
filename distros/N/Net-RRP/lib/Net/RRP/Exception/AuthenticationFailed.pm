package Net::RRP::Exception::AuthenticationFailed;

$Net::RRP::Exception::AuthenticationFailed::VERSION = '0.02';
@Net::RRP::Exception::AuthenticationFailed::ISA     = qw ( Net::RRP::Exception );

use strict;
use Net::RRP::Exception;

sub new
{
    my $class = shift;
    $class->SUPER::new ( -value => 530,
			 -text  => 'Authorization failed' );
}

1;
