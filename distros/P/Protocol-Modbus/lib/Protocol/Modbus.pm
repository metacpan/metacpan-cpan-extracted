package Protocol::Modbus;

use 5.006001;
use strict;
use warnings;
use Protocol::Modbus::Request;
use Protocol::Modbus::Response;
use Protocol::Modbus::Transaction;
use Protocol::Modbus::Transport;
use Protocol::Modbus::Exception;
use Carp;

#------------------------------------------------
#         Modbus module version
#------------------------------------------------
our $VERSION = '0.10';

#------------------------------------------------
#         Modbus related CONSTANTS
#------------------------------------------------

# Function codes
use constant FUNC_READ_COILS             => 0x01;
use constant FUNC_READ_INPUTS            => 0x02;
use constant FUNC_READ_HOLD_REGISTERS    => 0x03;
use constant FUNC_READ_INPUT_REGISTERS   => 0x04;
use constant FUNC_WRITE_COIL             => 0x05;
use constant FUNC_WRITE_REGISTER         => 0x06;
use constant FUNC_READ_EXCEPTION_STATUS  => 0x07;
use constant FUNC_DIAGNOSTICS            => 0x08;
use constant FUNC_GET_COMM_EVENT_COUNTER => 0x0B;
use constant FUNC_GET_COMM_EVENT_LOG     => 0x0C;
use constant FUNC_WRITE_COILS            => 0x0F;
use constant FUNC_WRITE_REGISTERS        => 0x10;
use constant FUNC_REPORT_SLAVE_ID        => 0x11;
use constant FUNC_READ_FILE_RECORD       => 0x1406;
use constant FUNC_WRITE_FILE_RECORD      => 0x1506;
use constant FUNC_MASK_WRITE_REGISTER    => 0x16;
use constant FUNC_RW_MULTIPLE_REGISTERS  => 0x17;
use constant FUNC_READ_FIFO_QUEUE        => 0x18;
use constant FUNC_CANOPEN_GEN_REFERENCE  => 0x2B0D;
use constant FUNC_READ_DEVICE_ID         => 0x2B0E;

# Parameter types
use constant PARAM_ADDRESS       => 1;
use constant PARAM_QUANTITY      => 2;
use constant PARAM_VALUE         => 3;
use constant PARAM_COUNT         => 4;
use constant PARAM_OUTPUTS       => 5;
use constant PARAM_MASK          => 6;
use constant PARAM_IS_LIST       => 8;
use constant PARAM_OUTPUT_LIST   => 8;
use constant PARAM_REGISTER_LIST => 9;

# How parameters are managed
#
# `n' => Big-endian word  (16 bit)
# 'C' => Unsigned char     (8 bit)
#
use constant PARAM_SPEC => [
    undef,    # 0
    ['address',  2, 'n'],     # 1
    ['quantity', 2, 'n'],     # 2
    ['value',    2, 'n'],     # 3
    ['count',    1, 'C'],     # 4
    ['outputs',  0, 'n*'],    # 5
    ['mask',     2, 'n'],     # 6
    undef,                    # 7
    ['outputs',   0, 'n*'],   # 8
    ['registers', 0, 'n*'],   # 9
];

#
# Class constructor
#
sub new {
    my ($obj, %args) = @_;
    my $class = ref($obj) || $obj;
    my $self = {_options => {%args},};

    # If driver property specified, load "additional" modbus class (TCP / RTU)
    if (exists $args{driver} && $args{driver} ne '') {
        $class = "Protocol::Modbus::$args{driver}";
        eval "use $class";
        if ($@) {
            croak("Protocol::Modbus driver `$args{driver}' failed to load: $@");
            return (undef);
        }
    }

    bless $self, $class;
}

# Build a read coils request
sub readCoilsRequest {
    my ($self, %args) = @_;
    $args{function} = &Protocol::Modbus::FUNC_READ_COILS;
    return $self->request(%args);
}

sub readInputsRequest {
    my ($self, %args) = @_;
    $args{function} = &Protocol::Modbus::FUNC_READ_INPUTS;
    return $self->request(%args);
}

sub readHoldRegistersRequest {
    my ($self, %args) = @_;
    $args{function} = &Protocol::Modbus::FUNC_READ_HOLD_REGISTERS;
    return $self->request(%args);
}

sub writeCoilRequest {
    my ($self, %args) = @_;
    $args{function} = &Protocol::Modbus::FUNC_WRITE_COIL;

    # The only allowed values are 0x0000 and 0xFF00
    if (!exists $args{value}) {
        return throw Protocol::Modbus::Exception(
            function => $args{function},
            code     => &Protocol::Modbus::Exception::ILLEGAL_DATA_VALUE
        );
    }
    elsif ($args{value} != 0) {

        # Don't throw exception, auto-convert value (it's more perlish)
        #
        #    return throw Protocol::Modbus::Exception(
        #      function => $args{function},
        #      code     => &Protocol::Modbus::Exception::ILLEGAL_DATA_VALUE
        #    );
        #
        $args{value} = 0xFF00;
    }

    return $self->request(%args);
}

sub writeRegisterRequest {
    my ($self, %args) = @_;
    $args{function} = &Protocol::Modbus::FUNC_WRITE_REGISTER;

    if (!exists $args{value}) {
        return throw Protocol::Modbus::Exception(
            function => $args{function},
            code     => &Protocol::Modbus::Exception::ILLEGAL_DATA_VALUE
        );
    }
    return $self->request(%args);
}

sub close {
    my $self      = $_[0];
    my $transport = $self->transport;
    my $ok        = 1;
    if ($self->transport->connected()) {
        $ok = $self->transport->disconnect();
    }
    return ($ok);
}

# "Pure" Modbus protocol doesn't need to add anything to requests
sub processBeforeSend {
    my ($self, $req) = @_;

    # noop
    return ($req);
}

sub processAfterReceive {
    my ($self, $res) = @_;
    return ($res);
}

# Build a generic request
sub request {
    my ($self, %req_params) = @_;
    if (!exists $req_params{function}) {
        croak('Invalid request() called without \'function\' parameter');
        return (undef);
    }

    my $req = Protocol::Modbus::Request->new(%req_params);

    # Add header and trailer (for TCP/RTU protocol flavours)
    $self->processBeforeSend($req);

    return ($req);
}

sub parseResponse {
    my ($self, $res) = @_;

    # Response at this stage is only initialized with raw frame
    # that came from transport layer

    # Let protocol layer "modify" raw data
    # For example, Modbus/TCP should strip out the MBAP header...
    $res = $self->processAfterReceive($res);

    # Invalid response!
    if (!$res) {
        warn('Received invalid response. Protocol layer refused data.');
        return (undef);
    }

    # Invalid PDU?
    if (!$res->pdu()) {
        warn('Invalid Modbus PDU!');
        return (undef);
    }

    # Ok, valid PDU. Process the response.
    return ($res->process());
}

sub transaction {
    my ($self, $trs, $req) = @_;
    my $oXact;

    if (!exists $self->{_transaction} || !$self->{_transaction}) {

        # Set transport object
        $self->transport($trs);

        # Create a new transaction
        #$self->{_transaction} =
        $oXact = Protocol::Modbus::Transaction->new(
            protocol  => $self,
            transport => $trs,
            request   => $req,
        );

        #warn('Create new transaction (id=', $oXact->id(), ')');
        #$self->{_transaction} = $oXact;
    }
    else {

        # Return the last generated transaction
        $oXact = $self->{_transaction};
    }

    return ($oXact);
}

sub transport {
    my $self = shift;
    if (@_) {
        $self->{_options}->{transport} = $_[0];
    }
    return ($self->{_options}->{transport});
}

sub options {
    my $self = $_[0];
    return $self->{_options};
}

1;

__END__

=head1 NAME

Protocol::Modbus - Implements Modbus protocol message generation and parsing

=head1 VERSION

This documentation relates to Protocol::Modbus version 0.01.
API is surely going to change! Warning! Beta-version ahead!

=head1 SYNOPSIS

  use Protocol::Modbus;

  # Initialize protocol object
  my $proto = Protocol::Modbus->new( driver=>'TCP', transport=>'TCP' );

  # Get a request object
  my $request = $proto->request(
      function => Protocol::Modbus::FUNC_READ_COILS, # or 0x01
      address  => 0x1234,
      quantity => 1,
      #unit     => 0x07, # Not required for Modbus/TCP
  );
  
  # ... or another way
  my $request = $proto->readInputsRequest(
      address  => 0,
      quantity => 64,
      #unit    => 0x07, # Not required for Modbus/TCP
  );

  # Dump request as binary packets
  print unpack('H*', $request->pdu()), "\n";

  # Pretty-print request on stdout
  print $request . "\n";   # Modbus Request PDU(......)
  print $request->stringify() . "\n";

  # Parse responses...
  #
  # TODO...

=head1 DESCRIPTION

Object-oriented class to abstract generation and parsing of Modbus protocol messages.
This class only handles protocol messages generation and parsing.
It does not directly interface with your PLC devices.
For that task, see the Device::PLC CPAN module (when that will be released).

Be sure to check out the C<examples> folder to see some scripts that
should work out of the box with a Modbus TCP server.

=head1 METHODS

Main methods are used to build Modbus requests.

=over *

=item  readCoilsRequest

=item  readInputsRequest

=item  readHoldRegistersRequest

=item  writeCoilRequest

=item  writeRegisterRequest

=back

=head1 STATUS

The set of classes is quite far from covering the whole Modbus protocol.
In particular, aspects related to mantaining the state of the modbus server
are completely skipped at this stage.

For now, there is only the main design and few more classes.
I only implemented the necessary things to make the examples work, that is
only simple requests with response parsing and coils status for example.

Further development will see the light when there's need and time...
I wouldn't be surprised if it doesn't work for you out-of-the-box.

=head1 SEE ALSO

=over 4

=item *

L<Device::PLC>

=item *

L<http://www.modbus.org>

=back

=head1 AUTHOR

Cosimo Streppone, E<lt>cosimo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Cosimo Streppone

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
