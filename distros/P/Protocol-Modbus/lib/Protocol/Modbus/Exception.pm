package Protocol::Modbus::Exception;

use strict;
use overload '""' => \&stringify;

use constant ILLEGAL_FUNCTION_CODE => 0x01;
use constant ILLEGAL_DATA_ADDRESS  => 0x02;
use constant ILLEGAL_DATA_VALUE    => 0x03;
use constant SERVER_FAILURE        => 0x04;
use constant ACKNOWLEDGE           => 0x05;
use constant SERVER_BUSY           => 0x06;
use constant GATEWAY_PROBLEM1      => 0x0A;
use constant GATEWAY_PROBLEM2      => 0x0B;

sub new {
    my ($obj, %args) = @_;
    my $class = ref($obj) || $obj;
    my $self = {%args};
    bless $self, $class;
}

# Fallback on 'new()'
*throw = *new;

sub code {
    my $self = $_[0];
    return $self->{code};
}

sub function {
    my $self = $_[0];
    return $self->{function};
}

sub stringify {
    my $self = $_[0];
    return sprintf('Modbus Exception (func=%s, code=%s)', $self->function, $self->code);
}

1;
