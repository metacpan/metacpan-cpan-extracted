package MouseX::AttributeHelpers;

use 5.006_002;
our $VERSION = '0.07';

use Mouse::Util qw(load_class);

# These submodules are automatically loaded by register_implementation()
#use MouseX::AttributeHelpers::Counter;
#use MouseX::AttributeHelpers::Number;
#use MouseX::AttributeHelpers::String;
#use MouseX::AttributeHelpers::Bool;
#use MouseX::AttributeHelpers::Collection::List;
#use MouseX::AttributeHelpers::Collection::Array;
#use MouseX::AttributeHelpers::Collection::ImmutableHash;
#use MouseX::AttributeHelpers::Collection::Hash;
#use MouseX::AttributeHelpers::Collection::Bag;

# aliases

foreach my $helper(qw(
    Bool Counter Number String
    Collection::List Collection::Array Collection::Bag
    Collection::Hash Collection::ImmutableHash
)){
    my $from = 'MouseX::AttributeHelpers::' . $helper;
    my $to   = 'Mouse::Meta::Attribute::Custom::'      . $helper;

    my $alias = sub {
        load_class($from);
        return $from;
    };
    no strict 'refs';
    *{$to . '::register_implementation'} = $alias;
}


1;
__END__

=head1 NAME

MouseX::AttributeHelpers - Extend your attribute interfaces

=head1 SYNOPSIS

    package MyClass;

    use Mouse;
    use MouseX::AttributeHelpers;

    has 'mapping' => (
        metaclass => 'Collection::Hash',
        is        => 'rw',
        isa       => 'HashRef',
        default   => sub { +{} },
        provides  => {
            exists => 'exists_in_mapping',
            keys   => 'ids_in_mapping',
            get    => 'get_mapping',
            set    => 'set_mapping',
        },
    );

    package main;

    my $obj = MyClass->new;
    $obj->set_quantity(10);      # quantity => 10
    $obj->set_mapping(4, 'foo'); # 4 => 'foo'
    $obj->set_mapping(5, 'bar'); # 5 => 'bar'
    $obj->set_mapping(6, 'baz'); # 6 => 'baz'

    # prints 'bar'
    print $obj->get_mapping(5) if $obj->exists_in_mapping(5);

    # prints '4, 5, 6'
    print join ', ', $obj->ids_in_mapping;

=head1 DESCRIPTION

MouseX::AttributeHelpers provides commonly used attribute helper
methods for more specific types of data.

As seen in the L</SYNOPSIS>, you specify the extension via the
C<metaclass> parameter.

=head1 PARAMETERS

=head2 provides

This points to a hashref that uses C<provider> for the keys and
C<method> for the values. The method will be added to the object
itself and do what you want.

=head2 curries

This points to a hashref that uses C<provider> for the keys and
has two choices for the value:

You can supply C<< { method => \@args } >> for the values.
The method will be added to the object itself (always using C<@args>
as the beginning arguments).

Another approach to curry a method provider is to supply a coderef
instead of an arrayref. The code ref takes C<$self>, C<$body>,
and any additional arguments passed to the final method.

=head1 METHOD PROVIDERS

=head2 L<Counter|MouseX::AttributeHelpers::Counter>

Methods for incrementing and decrementing a counter attribute.

=head2 L<Number|MouseX::AttributeHelpers::Number>

Common numerical operations.

=head2 L<String|MouseX::AttributeHelpers::String>

Common methods for string values.

=head2 L<Bool|MouseX::AttributeHelpers::Bool>

Common methods for boolean values.

=head2 L<Collection::List|MouseX::AttributeHelpers::Collection::List>

Common list methods for array references.

=head2 L<Collection::Array|MouseX::AttributeHelpers::Collection::Array>

Common methods for array references.

=head2 L<Collection::ImmutableHash|MouseX::AttributeHelpers::Collection::ImmutableHash>

Common methods for hash references.

=head2 L<Collection::Hash|MouseX::AttributeHelpers::Collection::Hash>

Common additional methods for hash references.

=head2 L<Collection::Bag|MouseX::AttributeHelpers::Collection::Bag>

Methods for incrementing and decrementing a value of collection.

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 THANKS TO

L<MooseX::AttributeHelpers/AUTHOR>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mouse>

L<MouseX::AttributeHelpers::Counter>,
L<MouseX::AttributeHelpers::Number>,
L<MouseX::AttributeHelpers::String>,
L<MouseX::AttributeHelpers::Bool>,
L<MouseX::AttributeHelpers::Collection::List>,
L<MouseX::AttributeHelpers::Collection::Array>,
L<MouseX::AttributeHelpers::Collection::ImmutableHash>,
L<MouseX::AttributeHelpers::Collection::Hash>,
L<MouseX::AttributeHelpers::Collection::Bag>

L<MooseX::AttributeHelpers>

=cut
