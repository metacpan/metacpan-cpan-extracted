package OpenStack::MetaAPI::Roles::GetFromId;

use strict;
use warnings;

use Moo::Role;

# RFC 4122 UUID: 8-4-4-4-12 hex groups
my $VALID_UUID = qr{^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$}i;

sub _get_from_id_spec {
    my ($self, $route, $id) = @_;

    die "route must be defined when using get_from_id" unless defined $route;
    die "invalid route '$route' - must starts with /"  unless $route =~ m{^/};
    die "Undefined 'id' for route '$route'"            unless defined $id;
    die "Invalid UUID format '$id' for route '$route' - expected 8-4-4-4-12 hex format"
        unless $id =~ $VALID_UUID;

    $route .= '/' unless $route =~ m{/$};

    #my $uri = $self->root_uri( $route );

    my $answer = $self->get($route);

    if (ref $answer eq 'HASH' && scalar keys %$answer == 1) {
        my ($mainkey) = keys %$answer;
        return $answer->{$mainkey};
    }

    return $answer;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::Roles::GetFromId

=head1 VERSION

version 0.004

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
