package Net::Cisco::FMC::v1::Role::ObjectMethods;
$Net::Cisco::FMC::v1::Role::ObjectMethods::VERSION = '0.005001';
# ABSTRACT: Role for Cisco Firepower Management Center (FMC) API version 1 method generation

use 5.024;
use feature 'signatures';
use MooX::Role::Parameterized;
use Carp;
use Clone qw( clone );
use Moo::Role; # last for cleanup

no warnings "experimental::signatures";

requires qw( _create _list _get _update _delete );








role {
    my $params = shift;
    my $mop    = shift;

    $mop->method('create_' . $params->{singular} => sub ($self, $object_data) {
        return $self->_create(join('/',
            '/api/fmc_config/v1/domain',
            $self->domain_uuid,
            $params->{path},
            $params->{object}
        ), $object_data);
    });

    $mop->method('list_' . $params->{object} => sub ($self, $query_params = {}) {
        return $self->_list(join('/',
            '/api/fmc_config/v1/domain',
            $self->domain_uuid,
            $params->{path},
            $params->{object}
        ), $query_params);
    });

    $mop->method('get_' . $params->{singular} => sub ($self, $id, $query_params = {}) {
        return $self->_get(join('/',
            '/api/fmc_config/v1/domain',
            $self->domain_uuid,
            $params->{path},
            $params->{object},
            $id
        ), $query_params);
    });

    $mop->method('update_' . $params->{singular} => sub ($self, $object, $object_data) {
        my $id = $object->{id};
        return $self->_update(join('/',
            '/api/fmc_config/v1/domain',
            $self->domain_uuid,
            $params->{path},
            $params->{object},
            $id
        ), $object, $object_data);
    });

    $mop->method('delete_' . $params->{singular} => sub ($self, $id) {
        return $self->_delete(join('/',
            '/api/fmc_config/v1/domain',
            $self->domain_uuid,
            $params->{path},
            $params->{object},
            $id
        ));
    });

    $mop->method('find_' . $params->{singular} => sub ($self, $query_params = {}) {
        my $listname = 'list_' . $params->{object};
        for my $object ($self->$listname({ expanded => 'true' })->{items}->@*) {
            my $identical = 1;
            for my $key (keys $query_params->%*) {
                if ( ref $query_params->{$key} eq 'Regexp') {
                    if ($object->{$key} !~ $query_params->{$key}) {
                        $identical = 0;
                        last;
                    }
                }
                else {
                    if ($object->{$key} ne $query_params->{$key}) {
                        $identical = 0;
                        last;
                    }
                }
            }
            if ($identical) {
                return $object;
            }
        }
        croak "object not found";
    });
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Cisco::FMC::v1::Role::ObjectMethods - Role for Cisco Firepower Management Center (FMC) API version 1 method generation

=head1 VERSION

version 0.005001

=head1 SYNOPSIS

    package Net::Cisco::FMC::v1;
    use Moo;
    use Net::Cisco::FMC::v1::Role::ObjectMethods;

    Net::Cisco::FMC::v1::Role::ObjectMethods->apply([
        {
            path     => 'object',
            object   => 'portobjectgroups',
            singular => 'portobjectgroup',
        },
        {
            path     => 'object',
            object   => 'protocolportobjects',
            singular => 'protocolportobject',
        }
    ]);

    1;

=head1 DESCRIPTION

This role adds methods for the REST methods of a specific object named.

=head1 METHODS

=head2 create_$singular

Takes a hashref of attributes.

Returns the created object as hashref.

Throws an exception on error.

=head2 list_$object

Takes optional query parameters.

Returns a hashref with a single key 'items' that has a list of hashrefs
similar to the FMC API.

Throws an exception on error.

As the API only allows fetching 1000 objects at a time it works around that by
making multiple API calls.

=head2 get_$singular

Takes an object id and optional query parameters.

Returns the object as hashref.

Throws an exception on error.

=head2 update_$singular

Takes an object and a hashref of attributes.

Returns the updated object as hashref.

Throws an exception on error.

=head2 delete_$singular

Takes an object id.

Returns true on success.

Throws an exception on error.

=head2 find_$singular

Takes query parameters.

Returns the object as hashref on success.

Throws an exception on error.

As there is no API for searching by all attributes this method emulates this
by fetching all objects using the L<list_$object> method and performing the
search on the client.

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 - 2020 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
