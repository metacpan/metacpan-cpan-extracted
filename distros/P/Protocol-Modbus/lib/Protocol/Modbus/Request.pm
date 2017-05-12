package Protocol::Modbus::Request;

use strict;
use warnings;
use overload '""' => \&stringify;
use overload 'eq' => \&equals;

sub equals {
    my ($x, $y) = @_;
    $x->stringify() eq $y->stringify();    # or "$x" == "$y"
}

sub new {
    my ($obj, %args) = @_;
    my $class = ref($obj) || $obj;
    my $self = {_options => {%args},};
    bless $self, $class;
}

sub stringify {
    my $self = $_[0];
    my $pdu  = $self->pdu();
    my $str  = 'ModbusRequest PDU(' . unpack('H*', $pdu) . ')';
    return ($str);
}

sub pdu {
    my $self   = $_[0];
    my @struct = $self->structure();
    my $args   = $self->{_options};
    my $func   = $self->function();
    my $pdu    = pack('C', $func);

    for (@struct) {
        my $ptype = $_;
        my ($pname, $pbytes, $pformat) = @{&Protocol::Modbus::PARAM_SPEC->[$ptype]};

#warn('adding ', $pname, '(', $args->{$pname},') for ', $pbytes, ' bytes with pack format (', $pformat, ')');
        $pdu .= pack($pformat, $args->{$pname});
    }

    # Add optional header/trailer for (for Modbus/TCP, Modbus/RTU protocol flavours)
    $pdu = $self->header() . $pdu . $self->trailer();

    return ($pdu);
}

# Get/set request additional header (for TCP/IP, RTU protocol flavours)
sub header {
    my $self = shift;
    if (@_) {
        $self->{_header} = $_[0];
    }
    return ($self->{_header} || '');
}

# Get/set request additional trailer (for RTU?)
# TODO
sub trailer {
    my $self = shift;
    if (@_) {
        $self->{_trailer} = $_[0];
    }
    return ($self->{_trailer} || '');
}

# Given function code, return its structure (parameters)
sub structure {
    my $self   = $_[0];
    my $func   = $self->function();
    my @params = ();

    # Multiple read requests
    if (   $func == &Protocol::Modbus::FUNC_READ_COILS
        || $func == &Protocol::Modbus::FUNC_READ_INPUTS
        || $func == &Protocol::Modbus::FUNC_READ_HOLD_REGISTERS
        || $func == &Protocol::Modbus::FUNC_READ_INPUT_REGISTERS)
    {
        @params = (&Protocol::Modbus::PARAM_ADDRESS, &Protocol::Modbus::PARAM_QUANTITY);
    }

    # Single write requests
    elsif ($func == &Protocol::Modbus::FUNC_WRITE_COIL) {
        @params = (&Protocol::Modbus::PARAM_ADDRESS, &Protocol::Modbus::PARAM_VALUE,);
    }

    # Single write of register
    elsif ($func == &Protocol::Modbus::FUNC_WRITE_REGISTER) {
        @params = (&Protocol::Modbus::PARAM_ADDRESS, &Protocol::Modbus::PARAM_VALUE,);
    }
    else {
        warn("UNIMPLEMENTED REQUEST");
    }

    return (@params);
}

sub function {
    my $self = $_[0];
    return $self->{_options}->{function};
}

sub options {
    my $self = $_[0];
    return $self->{_options};
}

1;
