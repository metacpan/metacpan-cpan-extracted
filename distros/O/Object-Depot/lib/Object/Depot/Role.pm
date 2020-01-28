package Object::Depot::Role;
use strictures 2;

=encoding utf8

=head1 NAME

Object::Depot::Role - Expose Object::Depot as a global singleton.

=head1 SYNOPSIS

See L<Object::Depot/SYNOPSIS>.

=head1 DESCRIPTION

This role rolls up an L<Object::Depot> into a singleton available to
all code in your application.  This role is ideal for creating global,
simplified, and centralized access to shared resources such as
connections to internal and cloud services.

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
    my $depot = $class->depot();

    return if !$depot->_has_export_name();

    my $name = $depot->export_name();
    my $do_it = $depot->always_export();

    foreach my $arg (@_) {
        if (defined($arg) and $arg eq $name) {
            $do_it = 1;
            next;
        }

        croak sprintf(
            'Unknown export, %s, passed to %s',
            defined($arg) ? qq["$arg"] : 'undef',
            $target,
        );
    }

    return if !$do_it;

    my $sub = $class->can($name);
    $sub ||= subname $name => sub{ $class->fetch(@_) };

    {
        no strict 'refs';
        no warnings 'redefine';
        *{"$target\::$name"} = $sub
    }

    return;
}


=head1 CLASS ATTRIBUTES

=head2 depot

The L<Object::Depot> singleton object.  Will return C<undef> if
L</init_depot> has not yet been called.

=cut

sub depot {
    my ($class) = @_;
    return $DEPOTS{ $class };
}

=head1 CLASS METHODS

=head2 init_depot

    __PACKAGE__->init_depot( $depot );

Takes an L<Object::Depot> object and saves it for later retrieval by
L</depot>.

=cut

sub init_depot {
    my $class = shift;

    croak "init_depot() has already been called on $class"
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
        local $Carp::CarpInternal{ (__PACKAGE__) } = 1;
        return $class->depot->$method( @_ );
    });

    { no strict 'refs'; *{__PACKAGE__ . "::$method"} = $sub }
}

1;
__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

