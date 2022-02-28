package Class::NullChain;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Null );
    our $VERSION = 'v0.1.0';
};

1;

__END__

=encoding utf8

=head1 NAME

Class::NullChain - Null Value Chaining Object Class

=head1 SYNOPSIS

    # In your code:
    sub customer
    {
        my $self = shift( @_ );
        return( $self->error( "No customer id was provided" ) ) if( !scalar( @_ ) );
        return( $self->customer_info_to_object( @_ ) );
    }

    # And this method is called without providing an id, thus triggering an error,
    # but is chained. Upon error triggered by method "error", a Class::Null
    # object is returned
    my $name = $object->customer->name;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This package provides a null returned value that can be chained and ultimately return C<undef>.

This is designed for chained method calls and avoid the perl error C<called on undefined value>

See L<Module::Generic::Null> for more information.

=head1 SEE ALSO

L<Class::Array>, L<Class::Scalar>, L<Class::Number>, L<Class::Boolean>, L<Class::Assoc>, L<Class::File>, L<Class::DateTime>, L<Class::Exception>, L<Class::Finfo>, L<Class::NullChain>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

