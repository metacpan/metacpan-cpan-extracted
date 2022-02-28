package Class::Assoc;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Hash );
    our $VERSION = 'v0.1.0';
};

1;

__END__

=encoding utf8

=head1 NAME

Class::Assoc - A Hash Object Class

=head1 SYNOPSIS

    use Class::Assoc;
    my $bool = Class::Assoc->new;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This package provides a versatile hash class object for the manipulation and chaining of hash reference.

See L<Module::Generic::Hash> for more information.

=head1 SEE ALSO

L<Class::Array>, L<Class::Scalar>, L<Class::Number>, L<Class::Boolean>, L<Class::Assoc>, L<Class::File>, L<Class::DateTime>, L<Class::Exception>, L<Class::Finfo>, L<Class::NullChain>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

