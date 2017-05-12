package MooseX::AttributeHelpers::MethodProvider::Hash;
use Moose::Role;

our $VERSION = '0.25';

with 'MooseX::AttributeHelpers::MethodProvider::ImmutableHash';

sub set : method {
    my ($attr, $reader, $writer) = @_;
    if ($attr->has_type_constraint && $attr->type_constraint->isa('Moose::Meta::TypeConstraint::Parameterized')) {
        my $container_type_constraint = $attr->type_constraint->type_parameter;
        return sub { 
            my ( $self, @kvp ) = @_;
           
            my ( @keys, @values );

            while ( @kvp ) {
                my ( $key, $value ) = ( shift(@kvp), shift(@kvp) );
                ($container_type_constraint->check($value)) 
                    || confess "Value " . ($value||'undef') . " did not pass container type constraint '$container_type_constraint'";
                push @keys, $key;
                push @values, $value;
            }

            if ( @values > 1 ) {
                @{ $reader->($self) }{@keys} = @values;
            } else {
                $reader->($self)->{$keys[0]} = $values[0];
            }
        };
    }
    else {
        return sub {
            if ( @_ == 3 ) {
                $reader->($_[0])->{$_[1]} = $_[2]
            } else {
                my ( $self, @kvp ) = @_;
                my ( @keys, @values );

                while ( @kvp ) {
                    push @keys, shift @kvp;
                    push @values, shift @kvp;
                }

                @{ $reader->($_[0]) }{@keys} = @values;
            }
        };
    }
}

sub accessor : method {
    my ($attr, $reader, $writer) = @_;

    if ($attr->has_type_constraint && $attr->type_constraint->isa('Moose::Meta::TypeConstraint::Parameterized')) {
        my $container_type_constraint = $attr->type_constraint->type_parameter;
        return sub {
            my $self = shift;

            if (@_ == 1) { # reader
                return $reader->($self)->{$_[0]};
            }
            elsif (@_ == 2) { # writer
                ($container_type_constraint->check($_[1]))
                    || confess "Value " . ($_[1]||'undef') . " did not pass container type constraint '$container_type_constraint'";
                $reader->($self)->{$_[0]} = $_[1];
            }
            else {
                confess "One or two arguments expected, not " . @_;
            }
        };
    }
    else {
        return sub {
            my $self = shift;

            if (@_ == 1) { # reader
                return $reader->($self)->{$_[0]};
            }
            elsif (@_ == 2) { # writer
                $reader->($self)->{$_[0]} = $_[1];
            }
            else {
                confess "One or two arguments expected, not " . @_;
            }
        };
    }
}

sub clear : method {
    my ($attr, $reader, $writer) = @_;
    return sub { %{$reader->($_[0])} = () };
}

sub delete : method {
    my ($attr, $reader, $writer) = @_;
    return sub { 
        my $hashref = $reader->(shift);
        CORE::delete @{$hashref}{@_};
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::MethodProvider::Hash

=head1 VERSION

version 0.25

=head1 DESCRIPTION

This is a role which provides the method generators for 
L<MooseX::AttributeHelpers::Collection::Hash>.

This role is composed from the 
L<MooseX::AttributeHelpers::Collection::ImmutableHash> role.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 PROVIDED METHODS

=over 4

=item B<count>

Returns the number of elements in the hash.

=item B<delete>

Removes the element with the given key

=item B<defined>

Returns true if the value of a given key is defined

=item B<empty>

If the list is populated, returns true. Otherwise, returns false.

=item B<clear>

Unsets the hash entirely.

=item B<exists>

Returns true if the given key is present in the hash

=item B<get>

Returns an element of the hash by its key.

=item B<keys>

Returns the list of keys in the hash.

=item B<set>

Sets the element in the hash at the given key to the given value.

=item B<values>

Returns the list of values in the hash.

=item B<kv>

Returns the  key, value pairs in the hash

=item B<accessor>

If passed one argument, returns the value of the requested key. If passed two
arguments, sets the value of the requested key.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-AttributeHelpers>
(or L<bug-MooseX-AttributeHelpers@rt.cpan.org|mailto:bug-MooseX-AttributeHelpers@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Stevan Little and Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
