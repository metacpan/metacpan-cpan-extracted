package Mojolicious::Plugin::Fondation::Action::Templates;
$Mojolicious::Plugin::Fondation::Action::Templates::VERSION = '0.01';
# ABSTRACT: Registers templates and zones from plugin share directories

use Mojo::Base 'Mojolicious::Plugin::Fondation::Action::Base', -signatures;

use Mojolicious::Plugin::Fondation::Utils qw(share_relative);

sub after_load ($self, $long, $conf, $share_dir) {
    return unless $share_dir && -d $share_dir;

    my $templates_dir = $share_dir->child('templates');
    return unless -d $templates_dir;

    my $manager = $self->manager;
    my $app     = $manager->app;
    my $short   = $manager->registry->{$long}{short_name};

    # Add templates directory (priority: "earlier in load_order = higher priority")
    push @{$app->renderer->paths}, $templates_dir->to_string;
    $self->log->debug("Added templates path: " . share_relative($templates_dir));

    # Register templates in the registry
    $self->_register_templates($long, $short, $templates_dir);
    $self->_register_zones($long, $short, $templates_dir);
}

sub _register_templates ($self, $long, $short, $templates_dir) {
    my $manager = $self->manager;
    my $entry   = $manager->registry->{$long} //= {};

    $entry->{templates} //= {};

    my @found_templates = ();

    $templates_dir->list_tree({ dir => 0 })->each(sub ($file, $idx) {
        # Accept .html.ep, .ep, .txt.ep, etc.
        return unless $file->basename =~ /\.(?:html?|txt|xml|json)\.ep$/i;

        my $rel_path      = $file->to_rel($templates_dir)->to_string;
        my $template_name = $rel_path;# =~ s/\.ep$//r;

        $entry->{templates}{$template_name} = {
            full_path     => $file->to_string,
            rel_path      => $rel_path,
            basename      => $file->basename,
            last_modified => $file->stat->mtime // 0,
        };

        push @found_templates, $template_name;
        $self->log->debug("Registered template: $template_name");
    });

}

sub _register_zones ($self, $long, $short, $templates_dir) {
    my $zone_base = $templates_dir->child('zones');
    return unless -d $zone_base;

    my $manager = $self->manager;
    my $entry   = $manager->registry->{$long};

    $entry->{zones} //= {};

    $zone_base->list_tree({ dir => 0 })->each(sub ($file, $idx) {
        my $basename = $file->basename;
        return unless $basename =~ /\.(html|js)\.ep$/i;

        my $type = lc $1;
        my $rel  = $file->to_rel($templates_dir)->to_string;
        my ($zone) = $rel =~ m{^zones/$type/(.+)/[^/]+$};

        $entry->{zones}{$type} //= {};
        $entry->{zones}{$type}{$zone} //= [];

        # HTML: store template name for render_to_string
        # JS:   pre-slurp content (no render needed)
        if ($type eq 'html') {
            my $template_name = $rel =~ s/\.html\.ep$//r;
            push @{$entry->{zones}{$type}{$zone}}, $template_name;
        }
        else {
            push @{$entry->{zones}{$type}{$zone}}, $file->slurp;
        }

        $self->log->debug("Registered zone: $rel ($type/$zone)");
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Action::Templates - Registers templates and zones from plugin share directories

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
