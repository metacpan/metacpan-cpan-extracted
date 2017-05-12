package Protocol::FIX::Message;

use strict;
use warnings;

use Protocol::FIX;

use mro;
use parent qw/Protocol::FIX::BaseComposite/;

our $VERSION = '0.04';    ## VERSION

=head1 NAME

Protocol::FIX::Message - FIX protocol message definition

=cut

=head1 METHODS

=head3 serialize

    serialize($self, $values)

Serializes provided values into string.

    $message->serialize([
        field => 'value',
        component => [
            other_field => 'value-2',
            group_field => [
                [some_field_1 => 'value-3.1.1', some_field_1 => 'value-3.1.2'],
                [some_field_1 => 'value-3.2.1', some_field_1 => 'value-3.2.2'],
            ],
        ],
    ]);

Error will be thrown if values do not conform the specification (e.g.
string provided, while integer is expected).

The B<managed fields> (BeginString, MsgType, and CheckSum) are calculated and
added to serialized string automatically.

=cut

sub serialize {
    my ($self, $values) = @_;

    # the SOH / trailing separator is part of the body, and it is included
    # in body length and checksum
    my $body = join($Protocol::FIX::SEPARATOR, $self->{serialized}->{message_type}, $self->next::method($values), '');

    my $body_length = $self->{managed_composites}->{BodyLength}->serialize(length($body));

    my $header_body = join($Protocol::FIX::SEPARATOR, $self->{serialized}->{begin_string}, $body_length, $body);

    my $sum = 0;
    $sum += ord $_ for split //, $header_body;
    $sum %= 256;
    my $checksum = $self->{managed_composites}->{CheckSum}->serialize(sprintf('%03d', $sum));

    return $header_body . join($Protocol::FIX::SEPARATOR, $checksum, '');
}

=head1 METHODS (for protocol developers)

=head3 new

    new($class, $name, $category, $message_type, $composites, $protocol)

Creates new Message (performed by Protocol, when it parses XML definition)

=cut

sub new {
    my ($class, $name, $category, $message_type, $composites, $protocol) = @_;

    my $message_type_field = $protocol->field_by_name('MsgType');

    my $message_type_string = $message_type_field->{values}->{by_id}->{$message_type};
    die "specified message type '$message_type' is not available in protocol"
        unless defined $message_type_string;

    my $serialized_message_type = $message_type_field->serialize($message_type_string);

    die "message category must be defined"
        if (!defined($category) || $category !~ /.+/);

    my @all_composites = (@{$protocol->header->{composites}}, @$composites, @{$protocol->trailer->{composites}});

    my @body_composites;
    for (my $idx = 0; $idx < @all_composites; $idx += 2) {
        my $c = $all_composites[$idx];
        next if exists $protocol->managed_composites->{$c->{name}};

        push @body_composites, $c, $all_composites[$idx + 1];
    }

    my $obj = next::method($class, $name, 'message', \@body_composites);

    $obj->{category}   = $category;
    $obj->{serialized} = {
        begin_string => $protocol->{begin_string},
        message_type => $serialized_message_type,
    };
    $obj->{managed_composites} = {
        BodyLength => $protocol->field_by_name('BodyLength'),
        CheckSum   => $protocol->field_by_name('CheckSum'),
    };

    return $obj;
}

1;
