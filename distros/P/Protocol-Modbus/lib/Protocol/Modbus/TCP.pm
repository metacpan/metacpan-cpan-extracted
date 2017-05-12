package Protocol::Modbus::TCP;

use strict;
use warnings;
use Protocol::Modbus;
use Protocol::Modbus::Request;
use Carp;

# Derive from Protocol::Modbus
@Protocol::Modbus::TCP::ISA = 'Protocol::Modbus';

sub request {
    my ($self, %args) = @_;

    # Unit is useless in TCP/IP messages
    if (!exists $args{unit} || !$args{unit}) {
        $args{unit} = 0xFF;
    }

    # Pass control to super class
    return $self->SUPER::request(%args);
}

# Needed to encapsulate modbus request with the MBAP header
# to be transmitted via TCP/IP
sub requestHeader {
    my ($self, $req) = @_;

    # If not one, open a transaction
    my $trans = $self->transaction();

    my $req_pdu = $req->pdu();

    # Assemble MBAP Header as follows
    my $trans_id = $trans->id();
    my $proto_id = 0x0000;                  # Modbus = 0x0000
    my $length   = 1 + length $req_pdu;     # 1 Byte Unit + N bytes request
    my $unit     = $req->options->{unit};

    # Pack the MBAP header
    my $mbap = pack('nnnC', $trans_id, $proto_id, $length, $unit);

    #warn('Computed MBAP [' . unpack('H*', $mbap) . ']');
    return ($mbap);
}

sub extractPdu {
    my ($self, $transaction, $raw_data) = @_;
    my ($mbap, $pdu);

    # Match transaction ids
    my $prev_tid = $transaction->id();
    my $this_tid = ord substr($raw_data, 0, 1);

   # If transaction id does not match, we must ignore this message
   #if( $prev_tid != $this_tid )
   #{
   #    # XXX Raise exception?
   #    warn('Transaction IDs don\'t match (prev=', $prev_tid, ', this=', $this_tid, ')');
   #    return();
   #}

    # Now unpack the raw MBAP data into fields
    my ($tid, $protocol, $count, $unit) = unpack('nnnC', $raw_data);

    #warn('tid=', $tid);
    #warn('protocol=', $protocol);
    #warn('count=', $count);
    #warn('unit=', $unit);

    # Protocol id must be modbus (0x0000)
    if ($protocol != 0) {

        # XXX Raise exception?
        warn('Protocol isn\'t 0x0000 (Modbus)');
        return ();
    }

    # Shouldn't be?
    if ($unit != 0xFF) {

        # XXX So what?
    }

    # Split MBAP and PDU
    $mbap = substr($raw_data, 0, 7);
    $pdu  = substr($raw_data, 7, $count);

    return ($mbap, $pdu);
}

# Process binary data after receiving
# Protocol should be responsible for processing binary
# packets to obtain a single Modbus PDU frame
#
# Modbus/TCP packets are composed of [MBAP + PDU]
#
sub processAfterReceive {
    my ($self, $res) = @_;
    my $raw_data = $res->frame();
    my ($mbap, $pdu);

    # Check that MBAP header corresponds to current transaction
    my $trn = $self->transaction();

    #warn('Extracting PDU from [', uc unpack('H*', $raw_data), ']');

    eval { ($mbap, $pdu) = $self->extractPdu($trn, $raw_data); };
    if ($@) {
        warn('Exception generated! (', $@, ')');
        return ($@);
    }

    #warn('MBAP=[', unpack('H*', $mbap), ']');
    #warn('PDU =[', unpack('H*', $pdu ), ']');

    # Set response PDU field
    $res->pdu($pdu);

    return ($res);
}

# Process a request before sending on the wirea
# Add MBAP header
sub processBeforeSend {
    my ($self, $req) = @_;
    my $mbap = $self->requestHeader($req);
    $req->header($mbap);
    return ($req);
}

1;

