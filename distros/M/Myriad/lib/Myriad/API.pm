package Myriad::API;

use Myriad::Class;

use Myriad::Config;
use Myriad::Service::Remote;
use Myriad::Service::Storage;

our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::API - provides an API for Myriad services

=head1 SYNOPSIS

=head1 DESCRIPTION

Used internally within L<Myriad> services for providing access to
storage, subscription and RPC behaviour.

=cut

has $myriad;
has $service_name;
has $storage;
has $config;

BUILD (%args) {
    weaken($myriad = delete $args{myriad});
    $service_name = delete $args{service_name} // die 'need a service name';
    $config = delete $args{config} // {};
    $storage = Myriad::Service::Storage->new(
        prefix => $service_name,
        storage => $myriad->storage
    );
}

=head2 storage

Returns a L<Myriad::Role::Storage>-compatible instance for interacting with storage.

=cut

method storage () { $storage }

=head2 service_by_name

Returns a service proxy instance for the given service name.

This can be used to call RPC methods and act on subscriptions.

=cut

method service_by_name ($name) {
    return Myriad::Service::Remote->new(
        myriad             => $myriad,
        service_name       => $myriad->registry->make_service_name($name),
        local_service_name => $service_name
    );
}


=head2 config

Returns a L<Ryu::Observable> that hold the value of the configuration.

=cut

method config ($key) {
    my $pkg = caller;
    if($Myriad::Config::SERVICES_CONFIG{$pkg}->{$key}) {
        return $config->{$key};
    }
    Myriad::Exception::Config::UnregisteredConfig->throw(reason => "$key is not registred by service $service_name");
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

