package MooseX::AttributeHelpers::MethodProvider::ImmutableHash;
use Moose::Role;

our $VERSION = '0.25';

sub exists : method {
    my ($attr, $reader, $writer) = @_;
    return sub { CORE::exists $reader->($_[0])->{$_[1]} ? 1 : 0 };
}

sub defined : method {
    my ($attr, $reader, $writer) = @_;
    return sub { CORE::defined $reader->($_[0])->{$_[1]} ? 1 : 0 };
}

sub get : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        if ( @_ == 2 ) {
            $reader->($_[0])->{$_[1]}
        } else {
            my ( $self, @keys ) = @_;
            @{ $reader->($self) }{@keys}
        }
    };
}

sub keys : method {
    my ($attr, $reader, $writer) = @_;
    return sub { CORE::keys %{$reader->($_[0])} };
}

sub values : method {
    my ($attr, $reader, $writer) = @_;
    return sub { CORE::values %{$reader->($_[0])} };
}

sub kv : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        my $h = $reader->($_[0]);
        map {
            [ $_, $h->{$_} ]
        } CORE::keys %{$h}
    };
}

sub elements : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        my $h = $reader->($_[0]);
        map {
            $_, $h->{$_}
        } CORE::keys %{$h}
    };
}

sub count : method {
    my ($attr, $reader, $writer) = @_;
    return sub { scalar CORE::keys %{$reader->($_[0])} };
}

sub empty : method {
    my ($attr, $reader, $writer) = @_;
    return sub { scalar CORE::keys %{$reader->($_[0])} ? 1 : 0 };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::MethodProvider::ImmutableHash

=head1 VERSION

version 0.25

=head1 DESCRIPTION

This is a role which provides the method generators for
L<MooseX::AttributeHelpers::Collection::ImmutableHash>.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 PROVIDED METHODS

=over 4

=item B<count>

Returns the number of elements in the list.

=item B<empty>

If the list is populated, returns true. Otherwise, returns false.

=item B<exists>

Returns true if the given key is present in the hash

=item B<defined>

Returns true if the value of a given key is defined

=item B<get>

Returns an element of the hash by its key.

=item B<keys>

Returns the list of keys in the hash.

=item B<values>

Returns the list of values in the hash.

=item B<kv>

Returns the key, value pairs in the hash as array references

=item B<elements>

Returns the key, value pairs in the hash as a flattened list

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
