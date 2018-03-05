package Moo::Role::ToJSON;

use Types::Standard 'ArrayRef';
use Moo::Role;

# ABSTRACT: a Moo role for a TO_JSON method

our $VERSION = '0.02';

has serializable_attributes => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_serializable_attributes { [] }

sub TO_JSON {
    my $self = shift;

    my @attributes_to_serialize
        = $self->can('is_attribute_serializable')
        ? grep { $self->is_attribute_serializable($_) } @{$self->serializable_attributes}
        : @{$self->serializable_attributes};

    return {
        map +($_ => $self->$_), @attributes_to_serialize
    };
}

1;

__END__

=encoding utf8

=head1 NAME

Moo::Role::ToJSON - a Moo role for a TO_JSON method

=head1 SYNOPSIS

    package My::Message;
    use Moo;
    with 'Moo::Role::ToJSON';

    has feel_like_sharing => (is => 'rw', default => 0);
    has message => (is => 'ro', default => 'Hi Mum!');
    has secret  => (is => 'ro', default => 'I do not like eating healthily');

    sub _build_serializable_attributes { [qw/message secret/] }

    # optional instance method to selectively serialize an attribute
    sub is_attribute_serializable {
        my ($self, $attr) = @_;

        if ($attr eq 'secret' && !$self->feel_like_sharing) {
            # returning a false value won't include attribute when serializing
            return 0;
        }

        return 1;
    }

    1;

    # t/test.t
    use Test2::Bundle::More;
    use Test2::Tools::Compare;

    my $message = My::Message->new();
    is $message->TO_JSON => {message => 'Hi Mum!'};

    $message->feel_like_sharing(1);
    is $message->TO_JSON =>
        {message => 'Hi Mum!', secret => 'I do not like eating healthily'};

=head1 DESCRIPTION

L<Moo::Role::ToJSON> is a L<Moo::Role> which provides a L</TO_JSON> method for
your classes. The C<TO_JSON> method will returns a C<HASH> reference of all the
L</serializable_attributes>. It is your responsibility to ensure the attributes
in your classes can be directly encoded into C<JSON>.

=head1 ATTRIBUTES

L<Moo::Role::ToJSON> implements the following attributes.

=head2 serializable_attributes

    # optionally override serialized attributes on instantiation
    my $message = My::Message->new(
        serializable_attributes => [qw/feel_like_sharing message secret/]
    );

An C<ARRAY> reference of attributes to serialize. Typically this would be set
directly in your class, but the default attributes can be overridden per
instance as in the example above.

This attribute is provided as a C<lazy> L<Moo> attribute, as such, the
L</_build_serializable_attributes> builder should be used to set the default
serializable attributes.

All of the attributes must return data that can be directly encoded into JSON.

=head1 METHODS

L<Moo::Role::ToJSON> implements the following methods.

=head2 _build_serializable_attributes

    sub _build_serializable_attributes { [qw/message secret/] }

The builder method returning the list of attributes to serialize. This method
must return an C<ARRAY> reference.

=head2 TO_JSON

    use Mojo::JSON 'encode_json';

    my $message = My::Message->new();
    say encode_json $message;

Returns a C<HASH> reference representing your object. This is intended to be
used by any C<encode_json> function that checks for the availability of the
C<TO_JSON> method for blessed objects.

=head2 EXAMPLES

See C<t/complete.t> for a complete example.

=head1 AUTHOR

Paul Williams E<lt>kwakwa@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2018- Paul Williams

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBIx::Class::Helper::Row::ToJSON>,
L<Moo::Role>.

=cut
