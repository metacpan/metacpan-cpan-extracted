package Protocol::FIX::Group;

use strict;
use warnings;

use Protocol::FIX;

our $VERSION = '0.06';    ## VERSION

=head1 NAME

Protocol::FIX::Group - allows repetition of common fieds/groups/components

=cut

=head1 METHODS (for protocol developers)

=head3 new

    new($class, $name, $composites)

Creates new Group (performed by Protocol, when it parses XML definition)

=cut

use mro;
use parent qw/Protocol::FIX::BaseComposite/;

sub new {
    my ($class, $base_field, $composites) = @_;

    die "base field for group must be a class of 'Protocol::FIX::Field'"
        unless UNIVERSAL::isa($base_field, "Protocol::FIX::Field");

    die "type of base field must be strictly 'NUMINGROUP'"
        unless $base_field->{type} eq 'NUMINGROUP';

    my $obj = next::method($class, $base_field->{name}, 'group', $composites);

    $obj->{base_field} = $base_field;

    return $obj;
}

=head3 serialize

    serialize($self, $values)

Serializes array of C<$values>. Not for end-user usage. Please, refer
L<Message/"serialize">

=cut

sub serialize {
    my ($self, $repetitions) = @_;

    die '$repetitions must be ARRAY in $obj->serialize($repetitions)'
        unless ref($repetitions) eq 'ARRAY';

    die '@repetitions must be non-empty in $obj->serialize($repetitions)'
        if @$repetitions == 0;

    my @strings = ($self->{base_field}->serialize(scalar @$repetitions));

    for my $values (@$repetitions) {
        push @strings, $self->next::method($values);
    }

    return join $Protocol::FIX::SEPARATOR, @strings;
}

1;
