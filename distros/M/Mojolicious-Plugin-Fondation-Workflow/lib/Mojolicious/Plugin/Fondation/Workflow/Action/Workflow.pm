package Mojolicious::Plugin::Fondation::Workflow::Action::Workflow;
$Mojolicious::Plugin::Fondation::Workflow::Action::Workflow::VERSION = '0.02';
# ABSTRACT: Post-load action — copies plugin workflow YAMLs to share/workflows/

use Mojo::Base 'Mojolicious::Plugin::Fondation::Action::Base', -signatures;
use Workflow::Factory;

# ---------------------------------------------------------------------------
# after_load — called by Fondation Manager for each plugin
# ---------------------------------------------------------------------------

sub after_load ($self, $long, $conf, $share_dir) {
    return unless $share_dir && -d $share_dir;

    my $workflows_dir = $share_dir->child('workflows');
    return unless -d $workflows_dir;

    my $app      = $self->manager->app;
    my $out_dir  = $app->home->child('share', 'workflows');
    $out_dir->make_path unless -d $out_dir;

    my $factory  = Workflow::Factory->instance;
    my $copied   = 0;

    for my $file ($workflows_dir->list({dir => 0})->each) {
        next unless $file->basename =~ /^(.+)\.ya?ml$/i;
        my $type = $1;

        my $dest     = $out_dir->child($file->basename);
        my $existed  = -f $dest;

        # Copy to app's share/workflows/
        $file->copy_to($dest->to_string);
        $copied++;

        # Register with factory only on first run (before register() picks it up)
        # On subsequent runs, register() already loaded it from share/workflows/
        next if $existed;

        require YAML;
        my $yaml = eval { YAML::LoadFile($dest->to_string) };
        if ($@) {
            $self->log->warn("Failed to load workflow YAML $dest: $@");
            next;
        }

        $factory->add_config(
            workflow => [$yaml],
            action   => [$yaml],
        );

        $self->log->debug("Registered workflow '$type' from $dest");
    }

    return unless $copied;
    $self->log->info("$long: $copied workflow(s) copied to share/workflows/");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Workflow::Action::Workflow - Post-load action — copies plugin workflow YAMLs to share/workflows/

=head1 VERSION

version 0.02

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
