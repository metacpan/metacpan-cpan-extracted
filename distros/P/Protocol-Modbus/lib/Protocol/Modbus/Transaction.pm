package Protocol::Modbus::Transaction;

use strict;
use warnings;
use Protocol::Modbus::Request;
use Protocol::Modbus::Response;

# Define a progressive id
$Protocol::Modbus::Transaction::ID = 0;

sub new {
    my ($obj, %args) = @_;
    my $class = ref($obj) || $obj;
    my $self = {
        _request   => $args{request},
        _response  => $args{response},
        _protocol  => $args{protocol},
        _transport => $args{transport},
        _id        => Protocol::Modbus::Transaction::nextId(),
    };
    bless $self, $class;
}

# Get/set protocol class (Pure modbus or TCP modbus)
sub protocol {
    my $self = shift;
    if (@_) {
        $self->{_protocol} = $_[0];
    }
    return $self->{_protocol};
}

# Transport object (TCP or Serial)
sub transport {
    my $self = shift;
    if (@_) {
        $self->{_transport} = $_[0];
    }
    return $self->{_transport};
}

sub close {
    my $self = $_[0];
    $self->transport->disconnect();
    $self->request(undef);
    $self->response(undef);
}

sub execute {
    my $self = $_[0];
    my ($req, $res);

    # To execute a transaction, we must be connected
    if (!$self->transport->connect()) {
        croak('Modbus connection with server not available!');
        return (undef);
    }

    # We must have a request object
    if (!($req = $self->request())) {
        croak('Modbus transaction without request is not possible!');
        return (undef);
    }

    # Send request
    $self->transport->send($req);

    #warn('Sent [', $req, '] request object');

    # Get a response
    my $raw_data = $self->transport->receive($req);

    #warn('Received [', uc unpack('H*', $raw_data), '] data');

    # Init a response object with the data received by transport
    $res = Protocol::Modbus::Response->new(frame => $raw_data);

    # Protocol (TCP/RTU) should now parse the response
    return ($self->protocol->parseResponse($res));

}

sub id {
    my $self = $_[0];
    return $self->{_id};
}

sub nextId {
    return ($Protocol::Modbus::Transaction::ID++);
}

# Get/set request class
sub request {
    my $self = shift;
    if (@_) {
        $self->{_request} = $_[0];
    }
    return $self->{_request};
}

# Get/set response class
sub response {
    my $self = shift;
    if (@_) {
        $self->{_request} = $_[0];
    }
    return $self->{_request};
}

# TODO Convert transaction to string
sub stringify {
    my $self = $_[0];
    return 'TRANSACTION_STRING';
}

1;

__END__

=head1 NAME

Protocol::Modbus::Transaction - Modbus protocol request/response transaction

=head1 SYNOPSIS

  use Protocol::Modbus;

  # Initialize protocol object
  my $proto = Protocol::Modbus->new( driver=>'TCP' );

  # Get a request object
  my $req = $proto->request(
      function => Protocol::Modbus::FUNC_READ_COILS, # or 0x01
      address  => 0x1234,
      quantity => 1,
      unit     => 0x07, # Only has sense for Modbus/TCP
  );

  # Init transaction and execute it, obtaining a response
  my $trn = Protocol::Modbus::Transaction->new( request=>$req );
  my $res = $trn->execute();

  # Pretty-print response on stdout
  print $response . "\n";   # Modbus Response PDU(......)

  # ...
  # Parse response
  # ...

=head1 DESCRIPTION

Implements the basic Modbus transaction model, with request / response cycle.
Also responsible of raising exceptions (see C<Protocol::Modbus::Exception> class).

=head1 METHODS

=over +

=item protocol

Returns the protocol object in use. Should be an instance of
C<Protocol::Modbus> or its subclasses.

=item request

Get/set request object. Should be an instance of C<Protocol::Modbus::Request> class.

=item response

Get/set response object. Should be an instance of C<Protocol::Modbus::Response> class.

=item execute

Executes transaction, sending request to proper channel (depending on protocol at this time).
Returns a C<Protocol::Modbus::Response> object in case of successful transaction.
Returns a C<Protocol::Modbus::Exception> object in case of failure and exception raised.

=over

=head1 SEE ALSO

=over *

=item Protocol::Modbus::Exception

=back

=head1 AUTHOR

Cosimo Streppone, E<lt>cosimo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Cosimo Streppone

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
