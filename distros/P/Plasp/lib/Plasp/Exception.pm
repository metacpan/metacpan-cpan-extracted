package Plasp::Exception;

use Moo::Role;
use Types::Standard qw(Str Object);

use overload
    q{""}    => sub { $_[0]->as_string },
    fallback => 1;

=head1 NAME

Plasp::Exception - Basic Plasp Exception Role

=head1 SYNOPSIS

   package My::Exception;
   use Moo;

   with 'Plasp::Exception';

   # Elsewhere..
   My::Exception->throw( qq/Fatal exception/ );

=head1 DESCRIPTION

This is the basic Plasp Exception role which is basically a rip off of
L<Catalyst::Exception::Basic>.

=head1 ATTRIBUTES

=head2 message

Holds the exception message.

=cut

has message => (
    is      => 'ro',
    isa     => Str,
    default => sub { $! || '' },
);

has stack_trace => (
    is      => 'ro',
    isa     => Object,
);

=head1 METHODS

=head2 as_string

Stringifies the exception's message attribute.
Called when the object is stringified by overloading.

=cut

sub as_string {
    my ( $self ) = @_;
    return $self->message;
}

around BUILDARGS => sub {
    my ( $next, $class, @args ) = @_;
    if ( @args == 1 && !ref $args[0] ) {
        @args = ( message => $args[0] );
    }

    my $args = $class->$next( @args );
    $args->{message} ||= $args->{error}
        if exists $args->{error};

    return $args;
};

=head2 throw( $message )

=head2 throw( message => $message )

=head2 throw( error => $error )

Throws a fatal exception.

=cut

sub throw {
    my $class = shift;
    my $error = $class->new( @_ );
    die $error;
}

=head2 rethrow( $exception )

Rethrows a caught exception.

=cut

sub rethrow {
    my ( $self ) = @_;
    die $self;
}

1;

=head1 SEE ALSO

=over

=item * L<Catalyst::Exception>

=item * L<Catalyst::Exception::Interface>

=item * L<Catalyst::Exception::Basic>

=back
