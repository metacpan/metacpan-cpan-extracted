package Net::Checkpoint::Management::v1::Role::ObjectMethods;
$Net::Checkpoint::Management::v1::Role::ObjectMethods::VERSION = '0.001008';
# ABSTRACT: Role for Checkpoint Management API version 1.x method generation

use 5.024;
use feature 'signatures';
use MooX::Role::Parameterized;
use Carp::Clan qw(^Net::Checkpoint::Management::v1);
use Moo::Role; # last for cleanup

no warnings "experimental::signatures";

requires qw( _create _list _get _update _delete );








role {
    my $params = shift;
    my $mop    = shift;

    if (exists $params->{singular} && defined $params->{singular}) {
        $mop->method('create_' . $params->{singular} => sub ($self, $object_data) {
            return $self->_create(join('/',
                '/web_api',
                'v' . $self->api_version,
                $params->{create}
            ), $object_data);
        })
            if exists $params->{create} && defined $params->{create};

        $mop->method('get_' . $params->{singular} => sub ($self, $query_params = {}) {
            return $self->_get(join('/',
                '/web_api',
                'v' . $self->api_version,
                $params->{get}
            ), $query_params);
        })
            if exists $params->{get} && defined $params->{get};

        $mop->method('update_' . $params->{singular} => sub ($self, $object, $object_data) {
            my $updated_data = { %$object, %$object_data };
            if (exists $params->{id_keys} && ref $params->{id_keys} eq 'ARRAY') {
                # ensure that only a single key is passed to the update call
                # the order of keys is the priority
                my @id_keys = $params->{id_keys}->@*;
                while (my $key = shift @id_keys) {
                    last
                        if exists $updated_data->{$key}
                        && defined $updated_data->{$key};
                }
                delete $updated_data->{$_}
                    for @id_keys;
            }

            return $self->_update(join('/',
                '/web_api',
                'v' . $self->api_version,
                $params->{update}
            ), $updated_data);
        })
            if exists $params->{update} && defined $params->{update};

        $mop->method('delete_' . $params->{singular} => sub ($self, $object) {
            return $self->_delete(join('/',
                '/web_api',
                'v' . $self->api_version,
                $params->{delete}
            ), $object);
        })
            if exists $params->{delete} && defined $params->{delete};

        $mop->method('find_' . $params->{singular} => sub ($self, $search_params = {}, $query_params = {}) {
            my $listname = 'list_' . $params->{object};
            my $list_key = $params->{list_key};
            for my $object ($self->$listname({ 'details-level' => 'full', %$query_params })->{$list_key}->@*) {
                my $identical = 0;
                for my $key (keys $search_params->%*) {
                    if ( ref $search_params->{$key} eq 'Regexp') {
                        if ( exists $object->{$key}
                            && $object->{$key} =~ $search_params->{$key}) {
                            $identical++;
                        }
                    }
                    else {
                        if ( exists $object->{$key}
                            && $object->{$key} eq $search_params->{$key}) {
                            $identical++;
                        }
                    }
                }
                if ($identical == scalar keys $search_params->%*) {
                    return $object;
                }
            }
            croak "object not found";
        });
    }

    if (exists $params->{object} && defined $params->{object}) {
        $mop->method('list_' . $params->{object} => sub ($self, $query_params = {}) {
            return $self->_list(join('/',
                '/web_api',
                'v' . $self->api_version,
                $params->{list}
            ), $params->{list_key}, $query_params);
        });
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Checkpoint::Management::v1::Role::ObjectMethods - Role for Checkpoint Management API version 1.x method generation

=head1 VERSION

version 0.001008

=head1 SYNOPSIS

    package Net::Checkpoint::Management::v1;
    use Moo;
    use Net::Checkpoint::Management::v1::Role::ObjectMethods;

    Net::Checkpoint::Management::v1::Role::ObjectMethods->apply([
        {
            object   => 'packages',
            singular => 'package',
            create   => 'add-package',
            list     => 'show-packages',
            get      => 'show-package',
            update   => 'set-package',
            delete   => 'delete-package',
            list_key => 'packages',
            id_keys  => [qw( uid name )],
        },
        {
            object   => 'accessrules',
            singular => 'accessrule',
            create   => 'add-access-rule',
            list     => 'show-access-rulebase',
            get      => 'show-access-rule',
            update   => 'set-access-rule',
            delete   => 'delete-access-rule',
            list_key => 'rulebase',
            id_keys  => ['uid', 'name', 'rule-number'],
        },
    ]);

    1;

=head1 DESCRIPTION

This role adds methods for the commands of a specific object.

=head1 METHODS

=head2 create_$singular

Takes a hashref of attributes.

Returns the created object as hashref.

Throws an exception on error.

=head2 list_$object

Takes optional query parameters.

Returns a hashref similar to the Checkpoint Management API but without the
'from' and 'to' keys.

Throws an exception on error.

As the API only allows fetching 500 objects at a time it works around that by
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

Takes a hashref of attributes uniquely identifying the object.
For most objects the uid is sufficient, accessrule requires the layer uid too.

Returns true on success.

Throws an exception on error.

=head2 find_$singular

Takes search and optional query parameters.

Returns the object as hashref on success.

Throws an exception on error.

As there is no API for searching by all attributes this method emulates this
by fetching all objects using the L</list_$object> method and performing the
search on the client.

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
