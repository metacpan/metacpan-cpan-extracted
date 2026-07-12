package Mojolicious::Plugin::Fondation::Model::DBIx::Async::Action::DBIx;
$Mojolicious::Plugin::Fondation::Model::DBIx::Async::Action::DBIx::VERSION = '0.03';
# ABSTRACT: Post-load action — discovers and registers DBIC Result/ResultSet
# classes from plugins into the native DBIx::Class schema before workers fork.

use Mojo::Base 'Mojolicious::Plugin::Fondation::Action::Base', -signatures;

use Mojo::Loader 'find_modules';

sub after_load ($self, $long_name, $conf, $share_dir) {
    my $manager = $self->manager;
    my $app     = $manager->app;

    my $plugin_entry = $manager->registry->{$long_name};
    return unless $plugin_entry && $plugin_entry->{instance};

    my $short = $plugin_entry->{short_name};

    # DBIC namespaces
    my $schema_ns    = "${long_name}::Schema";
    my $result_ns    = "${schema_ns}::Result";
    my $resultset_ns = "${schema_ns}::ResultSet";

    # Module discovery
    my @result_modules    = find_modules($result_ns);
    my @resultset_modules = find_modules($resultset_ns);
    return unless @result_modules || @resultset_modules;

    # Get schema class name without triggering connect (no worker fork yet)
    my $c = $app->build_controller;
    return unless $c->has_helper('schema_class');
    my $schema_class = $c->schema_class;
    return unless $schema_class;

    # Ensure the schema class is loaded before we register sources on it
    eval "require $schema_class; 1" or do {
        $self->log->warn("[$short] Cannot load schema class $schema_class: $@");
        return;
    };

    # Register Result classes on the native schema class
    # (before workers fork — so they inherit the sources)
    my %registered_results;
    for my $module (@result_modules) {

        eval "require $module; 1" or do {
            $self->log->warn("[$short] Cannot load Result $module: $@");
            next;
        };

        my $source = eval { $module->result_source_instance };
        unless ($source) {
            $self->log->warn("[$short] Cannot get result_source_instance for $module: $@");
            next;
        }
        # Derive the source moniker from the class name (last segment(s)
        # after ::Result::), matching the standard DBIx::Class
        # load_namespaces convention (e.g. Result::UserGroup → 'UserGroup').
        my ($moniker) = $module =~ /::Result::(.+)$/;
        unless ($moniker) {
            $self->log->warn("[$short] Cannot derive moniker from $module");
            next;
        }

        eval { $schema_class->register_source($moniker, $source); 1 }
            or $self->log->warn("[$short] register_source failed for $moniker: $@");

        $registered_results{$moniker} = $module;
        $self->log->debug("[$short] Registered DBIC Result: $moniker ($module)");
    }

    # Discover ResultSets
    my @registered_resultsets;
    for my $module (@resultset_modules) {
        my ($rs_name) = $module =~ m{::ResultSet::([^:]+)$};
        next unless $rs_name;
        next if $rs_name =~ /Base$/i;
        push @registered_resultsets, $rs_name;
    }

    # Store metadata
    $plugin_entry->{dbic} = {
        result_classes => \%registered_results,
        resultsets     => [ sort @registered_resultsets ],
        total_added    => scalar(keys %registered_results) + scalar(@registered_resultsets),
        schema_ns      => $schema_ns,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Model::DBIx::Async::Action::DBIx - Post-load action — discovers and registers DBIC Result/ResultSet

=head1 VERSION

version 0.03

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
