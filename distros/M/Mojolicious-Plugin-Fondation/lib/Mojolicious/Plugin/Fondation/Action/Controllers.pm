package Mojolicious::Plugin::Fondation::Action::Controllers;
$Mojolicious::Plugin::Fondation::Action::Controllers::VERSION = '0.01';
# ABSTRACT: Auto-discovers controller classes under a plugin namespace

use Mojo::Base 'Mojolicious::Plugin::Fondation::Action::Base', -signatures;

use Mojo::Loader 'find_modules';

sub after_load ($self, $long_name, $conf, $share_dir) {
    my $manager = $self->manager;
    my $app     = $manager->app;

    my $plugin_entry = $manager->registry->{$long_name};
    return unless $plugin_entry;

    my $plugin = $plugin_entry->{instance};
    return unless $plugin && ref $plugin;

    my $short = $plugin_entry->{short_name};

    # Plugin's controller namespace
    my $controller_ns = "${long_name}::Controller";

    # Search for modules in this namespace, excluding base classes
    my @controllers = grep { !/::Base$/ } find_modules($controller_ns);

    # Always set metadata for introspection
    $plugin_entry->{metadata}{controllers_count} = scalar @controllers;
    $plugin_entry->{metadata}{controllers_ns}    = $controller_ns;

    return unless @controllers;

    # Add namespace to routes (once only)
    my $routes_ns = $app->routes->namespaces;
    unless (grep { $_ eq $controller_ns } @$routes_ns) {
        push @$routes_ns, $controller_ns;
        my $count = scalar @controllers;
        $self->log->debug("Controller namespace added: $controller_ns ($count controllers)");
    }

    # store the list of controller names
    $plugin_entry->{controllers} = [ sort @controllers ];

    return $controller_ns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Action::Controllers - Auto-discovers controller classes under a plugin namespace

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
