package Protocol::FIX;
# ABSTRACT: Financial Information eXchange (FIX) messages parser/serializer

use strict;
use warnings;

use XML::Fast;
use File::ShareDir qw/dist_dir/;
use Path::Tiny;

use Protocol::FIX::Component;
use Protocol::FIX::Field;
use Protocol::FIX::Group;
use Protocol::FIX::BaseComposite;
use Protocol::FIX::Message;
use Protocol::FIX::Parser;
use Exporter qw/import/;

our @EXPORT_OK = qw/humanize/;
our $VERSION   = '0.06';

=head1 NAME

Protocol::FIX - Financial Information eXchange (FIX) messages parser/serializer

=head1 SYNOPSIS

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

=head1 DESCRIPTION

With this module you can easily create new FIX messages in human-readable way, i.e. use
names like OrderQty => '499', instead of directly wring string like '39=499'; and vise
versa, you can parse the gibberish FIX messages to access fields in human-readable way
too.

The module checks that mandatory fields are present, and that field values bypass
the validation.

=cut

my $distribution = 'Protocol-FIX';

my %MANAGED_COMPOSITES = map { $_ => 1 } qw/BeginString BodyLength MsgType CheckSum/;

my %specification_for = (fix44 => 'FIX44.xml');

our $SEPARATOR     = "\x{01}";
our $TAG_SEPARATOR = "=";

=head1 METHODS

=head3 new

    new($class, $version)

Creates new protocol instance for the specified FIX protocol version. Currently
shipped version is 'FIX44'.

The xml with protocol definition was taken at L<http://quickfixengine.org/>.

=cut

sub new {
    my ($class, $version) = @_;
    die("FIX protocol version should be specified")
        unless $version;

    my $file = $specification_for{lc $version};
    die("Unsupported FIX protocol version: $version. Supported versions are: " . join(", ", sort { $a cmp $b } keys %specification_for))
        unless $file;

    my $dir                 = $ENV{PROTOCOL_FIX_SHARE_DIR} // dist_dir($distribution);
    my $xml                 = path("$dir/$file")->slurp;
    my $protocol_definition = xml2hash $xml;
    my $obj                 = {
        version => lc $version,
    };
    bless $obj, $class;
    $obj->_construct_from_definition($protocol_definition);
    return $obj;
}

=head3 extension

    extension($self, $extension_path)

Modifies the protocol, by loading XML extension.

The extension might contain additional B<messages> or B<fields>.  The
extension XML should conform the format as the protocol definition itself,
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

=cut

sub extension {
    my ($self, $extension_path) = @_;

    my $xml        = path($extension_path)->slurp;
    my $definition = xml2hash $xml;

    my ($type, $major, $minor) = @{$definition->{fix}}{qw/-type -major -minor/};
    my $extension_id = join('.', $type, $major, $minor);
    my $protocol_id  = $self->{id};
    die("Extension ID ($extension_id) does not match Protocol ID ($protocol_id)")
        unless $extension_id eq $protocol_id;

    my $new_fields_lookup = $self->_construct_fields($definition);
    _merge_lookups($self->{fields_lookup}->{by_name},   $new_fields_lookup->{by_name});
    _merge_lookups($self->{fields_lookup}->{by_number}, $new_fields_lookup->{by_number});

    my $new_messsages_lookup = $self->_construct_messages($definition);
    _merge_lookups($self->{messages_lookup}->{by_name},   $new_messsages_lookup->{by_name});
    _merge_lookups($self->{messages_lookup}->{by_number}, $new_messsages_lookup->{by_number});

    return $self;
}

=head3 serialize_message

    serialize_message($self, $message_name, $payload)

Returns serialized string for the supplied C<$message_name> and C<$payload>.
Dies in case of end-user (developer) error, e.g. if mandatory field is
absent.

=cut

sub serialize_message {
    my ($self, $message_name, $payload) = @_;
    my $message = $self->message_by_name($message_name);
    return $message->serialize($payload);
}

=head3 parse_message

    parse_message($self, $buff_ref)

    my ($message_instance, $error) = $protocol->parse($buff_ref);

Tries to parse FIX message in the buffer refernce.

In the case of success it returns C<MessageInstance> and C<$error> is undef.
The string in C<$buff_ref> will be consumed.

In the case of B<protocol error>, the C<$message_instance> will be undef,
and C<$error> will contain the error description. The string in C<$buff_ref>
will be kept untouched.

In the case, when there is no enough data in C<$buff_ref> both C<$error>
and C<$message_instance> will be undef. The string in C<$buff_ref>
will be kept untouched, i.e. waiting futher accumulation of bytes from
network.

In other cases it dies; that indicates either end-user (developer) error
or bug in the module.

=cut

sub parse_message {
    return Protocol::FIX::Parser::parse(@_);
}

sub _construct_fields {
    my ($self, $definition) = @_;

    my $fields_lookup = {
        by_number => {},
        by_name   => {},
    };

    my $fields_arr = $definition->{fix}->{fields}->{field};
    $fields_arr = [$fields_arr] if ref($fields_arr) ne 'ARRAY';

    for my $field_descr (@$fields_arr) {
        my ($name, $number, $type) = map { $field_descr->{$_} } qw/-name -number -type/;
        my $values;
        my $values_arr = $field_descr->{value};
        if ($values_arr) {
            for my $value_desc (@$values_arr) {
                my ($key, $description) = map { $value_desc->{$_} } qw/-enum -description/;
                $values->{$key} = $description;
            }
        }
        my $field = Protocol::FIX::Field->new($number, $name, $type, $values);
        $fields_lookup->{by_number}->{$number} = $field;
        $fields_lookup->{by_name}->{$name}     = $field;
    }

    return $fields_lookup;
}

sub _get_composites {
    my ($values, $lookup) = @_;
    return () unless $values;

    my $array      = ref($values) ne 'ARRAY' ? [$values] : $values;
    my @composites = map {
        my $ref       = $_;
        my $name      = $ref->{-name};
        my $required  = $ref->{-required} eq 'Y';
        my $composite = $lookup->{by_name}->{$name};

        die($name) unless $composite;

        ($composite, $required);
    } @$array;
    return @composites;
}

sub _construct_components {
    my ($self, $definition, $fields_lookup) = @_;

    my $components_lookup = {
        by_name => {},
    };

    my @components_queue = map { $_->{-type} = 'component'; $_; } @{$definition->{fix}->{components}->{component}};
    OUTER:
    while (my $component_descr = shift @components_queue) {
        my @composites;
        my $name = $component_descr->{-name};

        my $fatal       = 0;
        my $eval_result = eval {
            push @composites, _get_composites($component_descr->{component}, $components_lookup);

            my $group_descr = $component_descr->{group};
            if ($group_descr) {
                my @group_composites;

                # we might fail to construct group as dependent components might not be
                # constructed yet
                push @group_composites, _get_composites($group_descr->{component}, $components_lookup);

                # now we should be able to construct group
                $fatal = 1;
                push @group_composites, _get_composites($group_descr->{field}, $fields_lookup);

                my $group_name = $group_descr->{-name};
                my $base_field = $fields_lookup->{by_name}->{$group_name}
                    // die("${group_name} refers field '${group_name}', which is not available");
                my $group = Protocol::FIX::Group->new($base_field, \@group_composites);

                my $group_required = $group_descr->{-required} eq 'Y';
                push @composites, $group => $group_required;
            }
            1;
        };
        if (!$eval_result) {
            die("$@") if ($fatal);
            # not constructed yet, postpone current component construction
            push @components_queue, $component_descr;
            next OUTER;
        }

        $eval_result = eval { push @composites, _get_composites($component_descr->{field}, $fields_lookup); 1 };
        if (!$eval_result) {
            # make it human friendly
            die("Cannot find field '$@' referred by '$name'");
        }

        my $component = Protocol::FIX::Component->new($name, \@composites);
        $components_lookup->{by_name}->{$name} = $component;
    }

    return $components_lookup;
}

sub _construct_composite {
    my ($self, $name, $descr, $fields_lookup, $components_lookup) = @_;

    my @composites;
    my $eval_result = eval {
        push @composites, _get_composites($descr->{field},     $fields_lookup);
        push @composites, _get_composites($descr->{component}, $components_lookup);
        1;
    };
    if (!$eval_result) {
        die("Cannot find composite '$@', referred in '$name'");
    }

    return Protocol::FIX::BaseComposite->new($name, $name, \@composites);
}

sub _construct_messages {
    my ($self, $definition) = @_;

    my $messages_lookup = {
        by_name   => {},
        by_number => {},
    };
    my $fields_lookup     = $self->{fields_lookup};
    my $components_lookup = $self->{components_lookup};

    my $messages_arr = $definition->{fix}->{messages}->{message};
    $messages_arr = [$messages_arr] unless ref($messages_arr) eq 'ARRAY';

    my @messages_queue = @$messages_arr;
    while (my $message_descr = shift @messages_queue) {
        my @composites;
        my ($name, $category, $message_type) = map { $message_descr->{$_} } qw/-name -msgcat -msgtype/;

        my $eval_result = eval {
            push @composites, _get_composites($message_descr->{field},     $fields_lookup);
            push @composites, _get_composites($message_descr->{component}, $components_lookup);
            1;
        };
        if (!$eval_result) {
            # make it human friendly
            die("Cannot find field '$@' referred by '$name'");
        }

        my $group_descr = $message_descr->{group};
        # no need to protect with eval, as all fields/components should be availble.
        # if something is missing this is fatal
        if ($group_descr) {
            my @group_composites;

            push @group_composites, _get_composites($group_descr->{component}, $components_lookup);
            push @group_composites, _get_composites($group_descr->{field},     $fields_lookup);

            my $group_name = $group_descr->{-name};
            my $base_field = $fields_lookup->{by_name}->{$group_name} // die("${group_name} refers field '${group_name}', which is not available");
            my $group      = Protocol::FIX::Group->new($base_field, \@group_composites);

            my $group_required = $group_descr->{-required} eq 'Y';
            push @composites, $group => $group_required;
        }

        my $message = Protocol::FIX::Message->new($name, $category, $message_type, \@composites, $self);
        $messages_lookup->{by_name}->{$name}           = $message;
        $messages_lookup->{by_number}->{$message_type} = $message;
    }

    return $messages_lookup;
}

sub _construct_from_definition {
    my ($self, $definition) = @_;

    my ($type, $major, $minor) = @{$definition->{fix}}{qw/-type -major -minor/};
    my $protocol_id = join('.', $type, $major, $minor);

    my $fields_lookup     = $self->_construct_fields($definition);
    my $components_lookup = $self->_construct_components($definition, $fields_lookup);

    my $header_descr  = $definition->{fix}->{header};
    my $trailer_descr = $definition->{fix}->{trailer};
    my $header        = $self->_construct_composite('header',  $header_descr,  $fields_lookup, $components_lookup);
    my $trailer       = $self->_construct_composite('trailer', $trailer_descr, $fields_lookup, $components_lookup);

    my $serialized_begin_string = $fields_lookup->{by_name}->{BeginString}->serialize($protocol_id);

    $self->{id}                = $protocol_id;
    $self->{header}            = $header;
    $self->{trailer}           = $trailer;
    $self->{fields_lookup}     = $fields_lookup;
    $self->{components_lookup} = $components_lookup;
    $self->{begin_string}      = $serialized_begin_string;

    my $messages_lookup = $self->_construct_messages($definition);
    $self->{messages_lookup} = $messages_lookup;

    return;
}

sub _merge_lookups {
    my ($old, $new) = @_;
    @{$old}{keys %$new} = values %$new;
    return;
}

=head1 METHODS (for protocol developers)

=head3 humanize

    humanize ($buffer)

Returns human-readable string for the buffer. I.e. is just substitutes
L<SOH|https://en.wikipedia.org/wiki/C0_and_C1_control_codes> to " | ".

This might be usable during development of own FIX-client/server.

=cut

sub humanize {
    my $s = shift;
    return $s =~ s/\x{01}/ | /gr;
}

=head3 is_composite

    is_composite($object)

Checks whether the supplied C<$object> conforms "composte" concept.
I.e. is it is L<Field>, L<LGroup>, L<Component> or L<Mesassage>.

=cut

sub is_composite {
    my $obj = shift;
    return
           defined($obj)
        && UNIVERSAL::can($obj, 'serialize')
        && exists $obj->{name}
        && exists $obj->{type};
}

=head3 field_by_name

    field_by_name($self, $field_name)

Returns Field object by it's name or dies with error.

=cut

sub field_by_name {
    my ($self, $field_name) = @_;
    my $field = $self->{fields_lookup}->{by_name}->{$field_name};
    if (!$field) {
        die("Field '$field_name' is not available in protocol " . $self->{version});
    }
    return $field;
}

=head3 field_by_number

    field_by_number($self, $field_number)

Returns Field object by it's number or dies with error.

=cut

sub field_by_number {
    my ($self, $field_number) = @_;
    my $field = $self->{fields_lookup}->{by_number}->{$field_number};
    if (!$field) {
        die("Field $field_number is not available in protocol " . $self->{version});
    }
    return $field;
}

=head3 component_by_name

    component_by_name($self, $name)

Returns Component object by it's name or dies with error.

=cut

sub component_by_name {
    my ($self, $name) = @_;
    my $component = $self->{components_lookup}->{by_name}->{$name};
    if (!$component) {
        die("Component '$name' is not available in protocol " . $self->{version});
    }
    return $component;
}

=head3 message_by_name

    message_by_name($self, $name)

Returns Message object by it's name or dies with error.

=cut

sub message_by_name {
    my ($self, $name) = @_;
    my $message = $self->{messages_lookup}->{by_name}->{$name};
    if (!$message) {
        die("Message '$name' is not available in protocol " . $self->{version});
    }
    return $message;
}

=head3 header

    header($self)

Returns Message's header

=cut

sub header {
    return shift->{header};
}

=head3 trailer

    trailer($self)

Returns Message's trailer

=cut

sub trailer {
    return shift->{trailer};
}

=head3 id

    id($self)

Returns Protocol's ID string, as it appears in FIX message (BeginString field).

=cut

sub id {
    return shift->{id};
}

=head3 managed_composites

    managed_composites()

Returns list of fields, managed by protocol. Currently the list consists of
fields: BeginString, MsgType, and CheckSum

=cut

sub managed_composites {
    return \%MANAGED_COMPOSITES;
}

1;
