package OpenStack::MetaAPI::API::Volume;

use strict;
use warnings;

use Moo;

extends 'OpenStack::MetaAPI::API::Service';

with 'OpenStack::MetaAPI::Roles::Listable';

# Block storage is in the catalogue under whichever versions the cloud still
# offers, and 'volume' unadorned is not always one of them -- a current
# deployment may list only volumev3 and volumev2.  So the type is whatever is
# actually there, newest first, rather than a name we picked in advance.
has '+name' => (
    required => 0,
    lazy     => 1,
    default  => sub {
        my ($self) = @_;

        my %offered = map { $_ => 1 } $self->auth->services;
        foreach my $type (qw{volumev3 volumev2 volume}) {
            return $type if $offered{$type};
        }

        die "This cloud offers no block storage service (looked for volumev3, volumev2, volume)\n";
    },
);

# Declared here rather than in a Specs data block.
#
# The spec package a service loads is named after its catalogue type -- so a
# cloud offering volumev3 would want Specs::Volumev3, and one offering volume
# would want Specs::Volume, for the same two routes.  Writing them out once is
# less work than one spec file per spelling.
sub volumes {
    my ($self, @args) = @_;

    return $self->_list(['/volumes', 'volumes'], \@args);
}

sub volume_from_uid {
    my ($self, $uid) = @_;

    die "volume id is required by volume_from_uid" unless defined $uid && length $uid;

    my $out = $self->get($self->root_uri("/volumes/$uid"));

    return ref $out ? $out->{volume} : $out;
}

sub create_volume {
    my ($self, %opts) = @_;

    die "'size' is required by create_volume" unless $opts{size};

    my $out = $self->post($self->root_uri('/volumes'), {volume => {%opts}});

    return ref $out ? $out->{volume} : $out;
}

sub delete_volume {
    my ($self, $uid) = @_;

    die "volume id is required by delete_volume" unless defined $uid && length $uid;

    return $self->delete($self->root_uri("/volumes/$uid"));
}

sub volume_limits {
    my ($self) = @_;

    my $out = $self->get($self->root_uri('/limits'));

    return ref $out ? $out->{limits} : $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::API::Volume

=head1 VERSION

version 0.004

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
