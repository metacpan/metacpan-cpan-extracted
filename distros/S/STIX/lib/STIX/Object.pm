package STIX::Object;

use 5.010001;
use strict;
use warnings;
use utf8;

use overload '""' => \&to_string, fallback => 1;

use Carp;
use Cpanel::JSON::XS;
use STIX::Schema;
use Types::Standard qw(Str);
use UUID::Tiny      qw(:std);

use Moo;
use namespace::autoclean;

use constant PROPERTIES => qw();

use constant STIX_OBJECT      => undef;
use constant STIX_OBJECT_TYPE => undef;

sub generate_id {

    my ($self, $ns, $name) = @_;

    my $type         = $self->STIX_OBJECT_TYPE;
    my $uuid_version = ($ns || $name) ? UUID_V5 : UUID_V4;

    Carp::carp 'Unknown object type' unless $type;

    return $self->generate_id_for_type($type, $ns, $name);

}

sub generate_id_for_type {

    my ($self, $type, $ns, $name) = @_;
    my $uuid_version = ($ns || $name) ? UUID_V5 : UUID_V4;
    return sprintf('%s--%s', $type, create_uuid_as_string($uuid_version, $ns, $name));

}

sub validate { STIX::Schema->new(object => shift)->validate }

sub to_string {

    my $self = shift;

    my $json = Cpanel::JSON::XS->new->utf8->canonical->allow_nonref->allow_unknown->allow_blessed->convert_blessed
        ->stringify_infnan->escape_slash(0)->allow_dupkeys->pretty;

    return $json->encode($self->TO_JSON);

}

sub to_hash {

    my $self = shift;

    my $json = $self->to_string;
    return Cpanel::JSON::XS->new->decode($json);

}

sub _render_object_ref {

    my $object = shift;

    if (ref($object) eq 'STIX::Common::Identifier') {
        return $object->to_string;
    }

    return $object->id;

}

sub TO_JSON {

    my $self = shift;

    my $json = {};

    foreach my $property ($self->PROPERTIES()) {

        if ($self->can($property)) {

            my $value = $self->$property;
            next unless defined $value;

            if (ref($value) && $property =~ /_ref$/) {
                $json->{$property} = _render_object_ref($value);
            }
            elsif ($property eq 'extensions') {

                $json->{extensions} = {};

                if (ref $value eq 'ARRAY' || ref($value) eq 'STIX::Common::List') {

                    foreach my $extension (@{$value}) {
                        if (ref $extension && $extension->EXTENSION_TYPE()) {
                            $json->{extensions}->{$extension->EXTENSION_TYPE()} = $extension;
                        }
                    }

                }

                if (ref $value eq 'HASH') {
                    $json->{extensions} = $value;
                }

            }
            elsif (ref($value) eq 'ARRAY' || ref($value) eq 'STIX::Common::List') {

                if (@{$value}) {

                    $json->{$property} = [];

                    foreach my $item (@{$value}) {
                        if ($property =~ /_refs$/ && ref($item)) {
                            push @{$json->{$property}}, _render_object_ref($item);
                        }
                        else {
                            push @{$json->{$property}}, $item;
                        }
                    }

                }

            }
            else {
                $json->{$property} = $value;
            }

        }

    }

    # Add custom properties
    if ($self->can('custom_properties')) {
        foreach my $custom_property (keys %{$self->custom_properties}) {
            $json->{$custom_property} = $self->custom_properties->{$custom_property};
        }
    }

    return $json;

}

1;

=encoding utf-8

=head1 NAME

STIX::Object - Base class for STIX Objects

=head2 HELPERS

=over

=item $object->generate_id ( [ $ns, $name | $name ] )

Generate STIX Identifier

    # Generate identifier (Object Type + UUIDv4)
    $id = $object->generate_id('CAPEC-1');

    # Generate identifier (Object Type + UUIDv5)
    $id = $object->generate_id($org_namespace, 'CAPEC-1');

=item $object->TO_JSON

Encode the object in JSON.

=item $object->to_hash

Return the object HASH.

=item $object->to_string

Encode the object in JSON.

=item $object->validate

Validate the object using JSON Schema
(see L<STIX::Schema>).

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
