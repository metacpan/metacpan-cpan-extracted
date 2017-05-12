package Starch::Util;
$Starch::Util::VERSION = '0.06';
=head1 NAME

Starch::Util - Utility functions used internally by Starch.

=cut

use Carp qw();
use Module::Runtime qw( require_module is_module_name );

use strictures 2;
use namespace::clean;

use Exporter qw( import );
our @EXPORT_OK;

=head1 FUNCTIONS

=head2 croak

This is a custom L<Carp> C<croak> function which sets various
standard starch packages as C<Internal> so that Carp looks
deeper in the stack for something to blame which makes exceptions
be more contextually useful for users of Starch and means we don't
need to use confess which generates giant stack traces.

=cut

push @EXPORT_OK, 'croak';
sub croak {
    local $Carp::Internal{'Starch::Factory'} = 1;
    local $Carp::Internal{'Starch::Manager'} = 1;
    local $Carp::Internal{'Starch::Plugin::AlwaysLoad'} = 1;
    local $Carp::Internal{'Starch::Plugin::Bundle'} = 1;
    local $Carp::Internal{'Starch::Plugin::CookieArgs::Manager'} = 1;
    local $Carp::Internal{'Starch::Plugin::CookieArgs::State'} = 1;
    local $Carp::Internal{'Starch::Plugin::DisableStore'} = 1;
    local $Carp::Internal{'Starch::Plugin::ForManager'} = 1;
    local $Carp::Internal{'Starch::Plugin::ForState'} = 1;
    local $Carp::Internal{'Starch::Plugin::ForStore'} = 1;
    local $Carp::Internal{'Starch::Plugin::LogStoreExceptions'} = 1;
    local $Carp::Internal{'Starch::Plugin::RenewExpiration::Manager'} = 1;
    local $Carp::Internal{'Starch::Plugin::RenewExpiration::State'} = 1;
    local $Carp::Internal{'Starch::Plugin::ThrottleStore'} = 1;
    local $Carp::Internal{'Starch::Plugin::Trace::Manager'} = 1;
    local $Carp::Internal{'Starch::Plugin::Trace::State'} = 1;
    local $Carp::Internal{'Starch::Plugin::Trace::Store'} = 1;
    local $Carp::Internal{'Starch::Role::Log'} = 1;
    local $Carp::Internal{'Starch::Role::MethodProxy'} = 1;
    local $Carp::Internal{'Starch::State'} = 1;
    local $Carp::Internal{'Starch::Store::Layered'} = 1;
    local $Carp::Internal{'Starch::Store::Memory'} = 1;
    local $Carp::Internal{'Starch::Store'} = 1;
    local $Carp::Internal{'Starch::Util'} = 1;

    return Carp::croak( @_ );
}

=head2 load_prefixed_module

    # These both return "Foo::Bar".
    my $module = load_prefixed_module( 'Foo', '::Bar' );
    my $module = load_prefixed_module( 'Foo', 'Foo::Bar' );

Takes a prefix to be appended to a relative package name and a
relative or absolute package name.  It then resolves the relative
package name to an absolute one, loads it, and returns the
absolute name.

=cut

push @EXPORT_OK, 'load_prefixed_module';
sub load_prefixed_module {
    my ($prefix, $module) = @_;

    $module = "$prefix$module" if $module =~ m{^::};

    require_module( $module );

    return $module;
}

=head2 apply_method_proxies

Given a data structures (array ref or hash ref) this will recursively
find all method proxies, call them, and insert the return value back
into the data structure.

This creates a new data structure and does not modify the original.

=cut

push @EXPORT_OK, 'apply_method_proxies';
sub apply_method_proxies {
    my ($data) = @_;

    return $data if !ref $data;

    if (ref($data) eq 'HASH') {
        return {
            map { $_ => apply_method_proxies( $data->{$_} ) }
            keys( %$data )
        };
    }
    elsif (ref($data) eq 'ARRAY') {
        if (is_method_proxy( $data )) {
            return call_method_proxy( $data );
        }

        return [
            map { apply_method_proxies( $_ ) }
            @$data
        ];
    }

    return $data;
}

=head2 call_method_proxy

    my @ret = call_method_proxy(
        [
            '&proxy'
            'Some::Package',
            'some_method',
            @args,
        ],
    );

Is the same as:

    require Some::Package;
    my @ret = Some::Package->some_method( @args );

Method proxies are defined in more detail at
L<Starch::Manual/METHOD PROXIES>.

=cut

push @EXPORT_OK, 'call_method_proxy';
sub call_method_proxy {
    my ($proxy) = @_;

    croak 'The method proxy is not an array ref with the first entry of "&proxy"'
        if !is_method_proxy( $proxy );

    my ($marker, $package, $method, @args) = @$proxy;

    croak "The method proxy package is undefined"
        if !defined $package;
    croak "The method proxy method is undefined"
        if !defined $method;

    croak "The method proxy package, '$package', is not a valid package name"
        if !is_module_name( $package );

    require_module($package);

    croak "The method proxy package, '$package', does not support the '$method' method"
        if !$package->can( $method );

    return $package->$method( @args );
}

=head2 is_method_proxy

    is_method_proxy( [ 'Foo', 'bar' ] ); # false
    is_method_proxy( [ '&proxy', 'Foo', 'bar' ] ); # true

Returns true if the passed value is an array ref where the first value
is C<&proxy>.

=cut

push @EXPORT_OK, 'is_method_proxy';
sub is_method_proxy {
    my ($proxy) = @_;
    return 0 if ref($proxy) ne 'ARRAY';
    return 1 if defined( $proxy->[0] ) and $proxy->[0] eq '&proxy';
    return 0;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

