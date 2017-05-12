package Nitesi::Provider::Role;

use strict;
use warnings;

use Moo::Role;

=head1 NAME

Nitesi::Provider::Role - Provider role for Nitesi Shop Machine

=head1 DESCRIPTION

Provides methods for dynamically composing objects from a number
of roles.

=head1 ATTRIBUTES

=head2 api_info

Returns hash reference with API information.

=cut

has api_info => (
    is => 'rw',
);

=head2 field_map

Maps field names.

=cut

has field_map => (
    is => 'rw',
);

=head2 attribute_map

Maps attribute to role providing the attribute (read-only).

=cut

has attribute_map => (
    is => 'ro',
    lazy => 1,
    builder => '_build_attribute_map',
);

=head2 base_role

Base role for the current object (read-only).

=cut

has base_role => (
    is => 'ro',
    lazy => 1,
    builder => '_base_role',
);

sub _base_role {
    my $self = shift;
    my @classes = grep {$_ ne 'WITH' && $_ ne 'AND'} split(/__/, ref($self));

    return $classes[0];
}

sub _build_attribute_map {
    my $self = shift;
    my (@classes, $name, $value, @attributes, %map, @rt_atts, %rt_map,
        $virtual, $foreign, $inherit, $att_settings);

    @classes = grep {$_ ne 'WITH' && $_ ne 'AND'} split(/__/, ref($self));

    # determine attributes of this and parent classes
    for my $role (@classes) {
        if (exists $self->api_info->{$role}->{attributes}) {
            $att_settings = $self->api_info->{$role}->{attributes};
        }
        else {
            $att_settings = {};
        }

        if (exists $self->api_info->{$role}->{virtual}) {
            $virtual = $self->api_info->{$role}->{virtual};
        }
        else {
            $virtual = {};
        }

        if (exists $self->api_info->{$role}->{foreign}) {
            $foreign = $self->api_info->{$role}->{foreign};
        }
        else {
            $foreign = {};
        }

        if (exists $self->api_info->{$role}->{inherit}) {
            $inherit =  $self->api_info->{$role}->{inherit};
        }
        elsif (exists $self->api_info->{$role}->{base}) {
            $inherit = $self->api_info->{$role}->{base};
        }

        $self->_lookup_attributes_from_moo($role, $role, \%map, $att_settings, $foreign, $virtual);

        if ($inherit && $classes[0] eq $role) {
            $self->_lookup_attributes_from_moo($inherit, $role, \%map, $att_settings, $foreign, $virtual);
        }

        @rt_atts = @{$Role::Tiny::INFO{$role}->{attributes} || []};
        %rt_map = @rt_atts;

        while (($name, $value) = each %rt_map) {
            next if $name =~ /^api_/;

            $map{$name} = {role => $role};

            if (exists $virtual->{$name}) {
                $map{$name}->{virtual} = $virtual->{$name};
            }
        }
    }

    if ($self->{field_map}) {
        my ($orig, $mapped);

        while (($orig, $mapped) = each %{$self->{field_map}}) {
            if (exists $map{$orig}) {
                $map{$orig}->{map} = $mapped;
            }
            else {
                die "Wrong entry in field_map: $orig.\n";
            }
        }
    }

    return \%map;
}

sub _lookup_attributes_from_moo {
    my ($self, $lookup, $role, $mapref, $att_settings, $foreign, $virtual) = @_;
    my ($name, $value);

    while (($name, $value) = each %{$Moo::MAKERS{$lookup}->{constructor}->{attribute_specs}}) {
        next if $name =~ /^api_/;

        $mapref->{$name} = {role => $role};

        if (exists $att_settings->{$name}) {
            if (defined $att_settings->{$name}) {
                $mapref->{$name}->{map} = $att_settings->{$name};
            }
            else {
                delete $mapref->{$name};
            }
        }

        if (exists $virtual->{$name}) {
            $mapref->{$name}->{virtual} = $virtual->{$name};
        }

        if (exists $foreign->{$name}) {
            $mapref->{$name}->{foreign} = $foreign->{$name};
        }
    }
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
