package Net::RRP::Exception;

use Error;

$Net::RRP::Exception::VERSION = '0.02';
@Net::RRP::Exception::ISA     = qw ( Error );

sub new
{
    my ( $class, %params ) = @_;
    $class->SUPER::new ( %params );
}

1;
