# NAME Protocol::FIX

![Build status](https://api.travis-ci.org/binary-com/perl-Protocol-FIX.png "Build status")
[![codecov](https://codecov.io/gh/binary-com/perl-Protocol-FIX/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Protocol-FIX)


# SYNOPSIS

    use Protocol::FIX;

    my $proto = Protocol::FIX->new('FIX44')->extension('t/data/extension-sample.xml');

    my $serialized = $proto->serialize_message('IOI', [
            SenderCompID => 'me',
            TargetCompID => 'you',
            MsgSeqNum    => 1,
            SendingTime  => '20090107-18:15:16',
            IOIID        => 'abc',
            IOITransType => 'CANCEL',
            IOIQty       => 'LARGE',
            Side         => 'BORROW',
            Instrument => [
                Symbol  => 'EURUSD',
                EvntGrp => [ NoEvents => [ [EventType => 'PUT'], [EventType => 'CALL'], [EventType => 'OTHER'] ] ],
            ],
            OrderQtyData  => [
                OrderQty => '499',
            ],
        ]);
    # managed fields (BeginString, MsgType, and CheckSum) are handled automatically,
    # no need to provide them

    my ($message_instance, $error) = $proto->parse_message(\$serialized);
    print("No error on parsing message");
    print "Message, ", $message_instance->name, " / ", $message_instance->category, "\n";

    print "Field 'SenderCompID' value: ", $message_instance->value('SenderCompID'), "\n";

    print "Component 'OrderQtyData' access: ",
        $message_instance->value('OrderQtyData')->value('OrderQty'), "\n";

    my $group = $message_instance->value('Instrument')->value('EvntGrp')->value('NoEvents');
    print "0th group 'NoEvents' of component 'Instrument/EvntGrp' access: ",
        $group->[0]->value('EventType'), "\n";

    my $buff = '';
    ($message_instance, $error) = $proto->parse_message(\$buff);
    # no error nor message_instance, as there is no enough data.

See also the "eg" folder for sample of FIX-server.

# METHODS

### new($class, $version)

Creates new protocol instance for the specified FIX protocol version. Currently
shipped version is 'FIX44'.

The xml with protocol definition was taken at [http://quickfixengine.org/](http://quickfixengine.org/).

### humanize ($buffer)

Returns human-readable string for the buffer. I.e. is just substitutes
[SOH](https://en.wikipedia.org/wiki/C0_and_C1_control_codes) to " | ".

This might be usable during development of own FIX-client/server.

### is\_composite($object)

Checks whether the supplied `$object` conforms "composte" concept.
I.e. is it is [Field](https://metacpan.org/pod/Field), [LGroup](https://metacpan.org/pod/LGroup), [Component](https://metacpan.org/pod/Component) or [Mesassage](https://metacpan.org/pod/Mesassage).

Not for end-user usage.

### field\_by\_name($self, $field\_name)

Returns Field object by it's name or dies with error.

Not for end-user usage.

### field\_by\_number($self, $field\_number)

Returns Field object by it's number or dies with error.

Not for end-user usage.

### component\_by\_name($self, $name)

Returns Component object by it's name or dies with error.

Not for end-user usage.

### message\_by\_name($self, $name)

Returns Message object by it's name or dies with error.

### header($self)

Returns Message's header

Not for end-user usage.

### trailer($self)

Returns Message's trailer

Not for end-user usage.

### id($self)

Returns Protocol's ID string, as it appears in FIX message (BeginString field).

Not for end-user usage.

### managed\_composites()

Returns list of fields, managed by protocol. Currently the list consists of
fields: BeginString, MsgType, and CheckSum

Not for end-user usage.

### serialize\_message($self, $message\_name, $payload)

Returns serialized string for the supplied `$message_name` and `$payload`.
Dies in case of end-user (developer) error, e.g. if mandatory field is
absent.

### parse\_message($self, $buff\_ref)

    my ($message_instance, $error) = $protocol->parse($buff_ref);

Tries to parse FIX message in the buffer refernce.

In the case of success it returns `MessageInstance` and `$error` is undef.
The string in `$buff_ref` will be consumed.

In the case of **protocol error**, the `$message_instance` will be undef,
and `$error` will contain the error description. The string in `$buff_ref`
will be kept untouched.

In the case, when there is no enough data in `$buff_ref` both `$error`
and `$message_instance` will be undef. The string in `$buff_ref`
will be kept untouched, i.e. waiting futher accumulation of bytes from
network.

In other cases it dies; that indicates either end-user (developer) error
or bug in the module.

### extension($self, $extension\_path)

Modifies the protocol, by loading XML extension.

The extension might contain additional **messages** or **fields**.  The
extenation XML should conform the format as the protocol definition itself,
i.e.:

    <fix type='FIX' major='4' minor='4' servicepack='0'>
            <messages>
                    <message name='Logon' msgtype='A' msgcat='admin'>
                            <field name='EncryptMethod' required='Y' />
                            <field name='HeartBtInt' required='Y' />
                            <field name='ResetSeqNumFlag' required='N' />
                            <field name='Username' required='N' />
                            <field name='Password' required='N' />
                            <field name='AwesomeField' required='Y' />
                    </message>
            </messages>
            <fields>
                    <field number='33000' name='AwesomeField' type='STRING' />
            </fields>
    </fix>
