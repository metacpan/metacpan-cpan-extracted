package Object::Depot::Singleton;
use strictures 2;

=encoding utf8

=head1 NAME

Object::Depot::Singleton - Expose an Object::Depot as a singleton.

=head1 SYNOPSIS

See L<Object::Depot/SYNOPSIS>.

=head1 DESCRIPTION

This role rolls up an L<Object::Depot> into a singleton
available to all code in your application.  This role is ideal for
creating global, simplified, and centralized access to shared
resources such as connections to internal and cloud services.

=cut

use Carp qw( croak );
use Object::Depot;
use Scalar::Util qw( blessed );
use Sub::Name qw( subname );

use Role::Tiny;
use namespace::clean;

my %DEPOTS;

sub import {
    my $class = shift;

    my $target = caller();
    $class->depot->_export( $target, @_ );

    return;
}

=head1 CLASS ATTRIBUTES

=head2 depot

The L<Object::Depot> singleton object.  Will return C<undef> if
L</init> has not yet been called.

=cut

sub depot {
    my ($class) = @_;
    return %DEPOTS{ $class };
}

=head1 CLASS METHODS

=head2 init

    __PACKAGE__->init( $depot );

Takes an L<Object::Depot> object and saves it for later retrieval by
L</depot>.

=cut

sub init {
    my $class = shift;

    croak "init() has already been called on $class"
        if $DEPOTS{ $class };

    if (@_==1 and blessed($_[0]) and $_[0]->isa('Object::Depot')) {
        $DEPOTS{ $class } = shift;
        return;
    }

    $DEPOTS{ $class } = Object::Depot->new( @_ );

    return;
}

=head1 PROXIED METHODS

These class methods proxy to the L</depot> object.

=over

=item L<Object::Depot/fetch>

=item L<Object::Depot/store>

=item L<Object::Depot/remove>

=item L<Object::Depot/create>

=item L<Object::Depot/arguments>

=item L<Object::Depot/declared_keys>

=item L<Object::Depot/inject>

=item L<Object::Depot/inject_with_guard>

=item L<Object::Depot/clear_injection>

=item L<Object::Depot/injection>

=item L<Object::Depot/has_injection>

=item L<Object::Depot/add_key>

=item L<Object::Depot/alias_key>

=back

=cut

foreach my $method (qw(
    fetch
    store
    remove
    create
    arguments
    declared_keys
    inject
    inject_with_guard
    clear_injection
    injection
    has_injection
    add_key
    alias_key
)) {
    my $sub = subname( $method => sub{
        my $class = shift;
        return $class->depot->$method( @_ );
    });

    { no strict 'refs'; *{__PACKAGE__ . "::$method"} = $sub }
}

1;
