package Test::Able::Object;

use Moose;
use strict;
use warnings;

extends( 'Moose::Object' );

=head1 NAME

Test::Able::Object - Test::Able's base object

=cut

=head1 DESCRIPTION

This object serves the same purpose as, and is a subclass of,
Moose::Object.

=head1 METHODS

=over

=item BUILD

Standard Moose BUILD method that builds all the test-related method
lists.

=cut

sub BUILD {
    my ( $self, ) = @_;

    $self->meta->current_test_object( $self, );
    $self->meta->build_all_methods;
    $self->meta->clear_current_test_object;

    return;
}

=item run_tests

A convenience method around L<Test::Able::Role::Meta::Class/run_tests>.  Can
be called as a class or instance method.

=back

=cut

sub run_tests {
    my ( $proto, ) = @_;

    my $self = ref $proto ? $proto : $proto->new;
    $self->meta->current_test_object( $self, );
    $self->meta->run_tests;
    $self->meta->clear_current_test_object;

    return;
}

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
