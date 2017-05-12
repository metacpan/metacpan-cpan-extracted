package Protocol::Modbus::Response;

use strict;
use warnings;
use overload '""' => \&stringify;
use overload 'eq' => \&equals;

use Protocol::Modbus::Exception;
use Carp;

our @in    = ();
our @coils = ();

sub equals {
    my ($x, $y) = @_;
    $x->stringify() eq $y->stringify();    # or "$x" == "$y"
}

#
# `frame' is required when calling constructor
#
sub new {
    my ($obj, %args) = @_;
    my $class = ref($obj) || $obj;

    $args{pdu} ||= $args{frame};

    my $self = {_options => {%args},};

    bless $self, $class;
}

sub stringify {
    my $self = $_[0];
    my $cRes = 'Modbus generic response';
    if ($self->{_function}) {
        $cRes = 'Modbus response (func=%s, address=%s, value=%s)';
        $cRes = sprintf($cRes, $self->{_function}, $self->{_address}, $self->{_value});
    }
    return ($cRes);
}

# Frame is the entire packet stream received from transport
sub frame {
    my $self = shift;
    if (@_) {
        $self->{_options}->{frame} = $_[0];
    }
    return ($self->{_options}->{frame});
}

# PDU is the "Pure" Modbus packet without transport headers
sub pdu {
    my $self = shift;
    if (@_) {
        $self->{_options}->{pdu} = $_[0];
    }
    return ($self->{_options}->{pdu});
}

sub process {
    my ($self, $pdu) = @_;

    # If binary packets not supplied, take them from constructor options ('frame')
    $pdu ||= $self->pdu();

    #warn('Parsing binary data [', unpack('H*', $pdu), ']');

    my $excep = 0;     # Modbus exception flag
    my $error = 0;     # Error in parsing response
    my $count = 0;     # How many bytes in response
    my @bytes = ();    # Hold response bytes

    # Get function code (only first char)
    my $func = ord substr($pdu, 0, 1);

    # Check if there was an exception (msb on)
    if ($func & 0x80) {

        # Yes, exception for function $func - 0x80
        $func -= 0x80;
        $excep = ord substr($pdu, 1, 1);
    }

    # There was an exception response. Throw exception!
    if ($excep > 0) {
        warn('Throw exception func=', $func, ' code=', $excep);
        return (throw Protocol::Modbus::Exception(function => $func, code => $excep));
    }

    #
    # Normal response
    # Decode bytes that arrived
    #
    if ($func == &Protocol::Modbus::FUNC_READ_COILS) {
        $count = ord substr($pdu, 1, 1);
        @bytes = split //, substr($pdu, 2);
        @coils = ();
        for (@bytes) {
            $_ = unpack('B*', $_);
            $_ = reverse;
            push @coils, split //;
        }
        $self->{_coils} = \@coils;
    }
    elsif ($func == &Protocol::Modbus::FUNC_READ_INPUTS) {
        $count = ord substr($pdu, 1, 1);
        @bytes = split //, substr($pdu, 2);
        @in = ();
        for (@bytes) {
            $_ = unpack('B*', $_);
            $_ = reverse;
            push @in, split //;
        }
        $self->{_inputs} = \@in;
    }
    elsif ($func == &Protocol::Modbus::FUNC_WRITE_COIL
        || $func == &Protocol::Modbus::FUNC_WRITE_REGISTER)
    {
        $self->{_function} = $func;
        $self->{_address}  = unpack 'n', substr($pdu, 1, 2);
        $self->{_value}    = unpack 'n', substr($pdu, 3, 2);
    }
    elsif ($func == &Protocol::Modbus::FUNC_READ_HOLD_REGISTERS) {
        $count = ord substr($pdu, 1, 1);
        @bytes = split //, substr($pdu, 2);
        @in = ();
        for (@bytes) {
            push @in, unpack('H*', $_);
        }
        $self->{_registers} = \@in;
    }
    return ($self);
}

sub coils {
    $_[0]->{_coils};
}

sub inputs {
    $_[0]->{_inputs};
}

sub registers {
    $_[0]->{_registers};
}

# Given function code, return response structure
sub structure {
    my ($self, $func) = @_;
    my @tokens = ();

    if (   $func == &Protocol::Modbus::FUNC_READ_COILS
        || $func == &Protocol::Modbus::FUNC_READ_INPUTS)
    {
        @tokens = (&Protocol::Modbus::PARAM_COUNT, &Protocol::Modbus::PARAM_STATUS_LIST,);
    }
    elsif ($func == &Protocol::Modbus::FUNC_READ_HOLD_REGISTERS
        || $func == &Protocol::Modbus::FUNC_READ_INPUT_REGISTERS)
    {
        @tokens =
            (&Protocol::Modbus::PARAM_COUNT, &Protocol::Modbus::PARAM_REGISTER_LIST,);
    }
    else {
        croak('UNIMPLEMENTED RESPONSE');
    }

    return (@tokens);
}

1;

