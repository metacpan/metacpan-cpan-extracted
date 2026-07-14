package Mojolicious::Plugin::Fondation::API;
$Mojolicious::Plugin::Fondation::API::VERSION = '0.05';
# ABSTRACT: Stable public contract for Fondation plugins -- read-only access

use Mojo::Base -base, -signatures;

has 'registry';
has 'load_order';

# ---------------------------------------------------------------------------
# plugin($name) -- returns a specific plugin's merged config hashref
#
# $name can be a short name ('Fondation::User') or a long name
# ('Mojolicious::Plugin::Fondation::User').
# Returns undef if the plugin is not in the registry.
# ---------------------------------------------------------------------------
sub plugin ($self, $name) {
    my $long = $self->_resolve_long($name);
    my $entry = $self->registry->{$long};
    return unless $entry;
    return $entry->{config};
}

# ---------------------------------------------------------------------------
# config($name) -- alias for plugin(), returns merged config
# ---------------------------------------------------------------------------
sub config ($self, $name) {
    return $self->plugin($name);
}

# ---------------------------------------------------------------------------
# _resolve_long -- normalizes a name to its long form
# ---------------------------------------------------------------------------
sub _resolve_long ($self, $name) {
    require Mojolicious::Plugin::Fondation::Utils;
    return Mojolicious::Plugin::Fondation::Utils::long_name($name);
}

sub find_template_source ($self, $name = '') {
    return undef unless $name && $self->registry && $self->load_order;

    # Normalize to .html.ep format
    my $normalized = $name;
    $normalized .= '.html.ep' unless $normalized =~ /\.html\.ep$/i;

    for my $long (@{$self->load_order}) {
        my $entry = $self->registry->{$long} or next;
        next unless $entry->{templates};

        if (exists $entry->{templates}{$normalized}) {
            return $entry->{short_name};
        }
    }
    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::API - Stable public contract for Fondation plugins -- read-only access

=head1 VERSION

version 0.05

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
