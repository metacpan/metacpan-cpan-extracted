package MooX::Clone;

use Moo ();
use Moo::Role ();

our $VERSION = "0.02";

sub import {
    my ($class, $type) = @_;

    my $target = caller;
    no strict 'refs';
    no warnings 'redefine';

    if ( ! $target->can('clone')
      && ! Moo::Role->does_role($target, 'MooX::Role::Clone')
    ) {
        Moo::Role->apply_single_role_to_package(
            $target,
            'MooX::Role::Clone'
        );
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

MooX::Clone - Make Moo objects clone-able

=head1 SYNOPSIS

    package Foo;
    use Moo;
    use MooX::Clone;

    has bar => ( is => 'rw' );

    package main;

    my $foo = Foo->new( bar => 1 );
    my $bar = $foo->clone;          # deep copy of $foo

=head1 DESCRIPTION

MooX::Clone lets you clone your Moo objects easily by adding a C<clone> method. It performs a deep copy of the entire object.

=head1 METHODS

=head2 clone

Clone the object. See L<Clone> for more details.

    my $bar = $foo->clone;

=head1 SEE ALSO

L<Clone>

=head1 LICENSE

Copyright (C) Julien Fiegehenn.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Julien Fiegehenn E<lt>simbabque@cpan.orgE<gt>

Mohammad S Anwar E<lt>mohammad.anwar@yahoo.comE<gt>

=cut
