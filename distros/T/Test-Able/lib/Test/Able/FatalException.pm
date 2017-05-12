package Test::Able::FatalException;

use Moose;
use overload
  '""' => sub { return shift->message; },
  fallback => 1;
use strict;
use warnings;

=head1 NAME

Test::Able::FatalException - Fatal Exception Class

=head1 SYNOPSIS

 Test::Able::FatalException->throw->( 'get me outta here - for real!' );

=head1 DESCRIPTION

Test::Able has special exception handling for the test-related methods.

This exception class is a means for breaking out of Test::Able's exception
smothering.

See L<Test::Able::Role::Meta::Class/on_method_exception> and
L<Test::Able::Role::Meta::Class/method_exceptions> for details.

=head1 ATTRIBUTES

=over

=item message

The text of the exception.

=back

=cut

has 'message' => ( is => 'rw', isa => 'Str', default => '', );

=head1 METHODS

=over

=item BUILDARGS

Standard Moose BUILDARGS method to allow single parameter construction.

=cut

sub BUILDARGS {
    my $class = shift;

    if ( @_ == 1 ) {
        return { message => $_[ 0 ], };
    }
    else {
        return { @_ };
    };
}

=item throw

Main method used to construct and throw an exception object.

=back

=cut

sub throw {
    my $class = shift;

    die $class->new( @_, );
}

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
