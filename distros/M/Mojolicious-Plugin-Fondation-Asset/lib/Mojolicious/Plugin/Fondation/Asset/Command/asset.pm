package Mojolicious::Plugin::Fondation::Asset::Command::asset;
$Mojolicious::Plugin::Fondation::Asset::Command::asset::VERSION = '0.03';
# ABSTRACT: Generate merged assetpack.def and process assets through AssetPack

use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::File 'path';

has description => 'Generate and process asset bundles';
has usage       => sub ($self) {
    <<"USAGE";
Usage: APPLICATION asset generate [OPTIONS]

  myapp.pl asset generate        Generate assets/assetpack.def and process
  myapp.pl asset generate -y     Force overwrite without prompt

USAGE
};

sub run ($self, @args) {
    my $app = $self->app;

    my $config = $app->defaults->{'asset.config'}
        or die "Asset not configured. Add Fondation::Asset to your config.\n";

    my $asset_dir = $config->{asset_dir} // 'share/assets';

    my $subcommand = shift @args || '';

    die $self->usage unless $subcommand eq 'generate';

    my $force = 0;

    while (@args) {
        my $arg = shift @args;
        if ($arg eq '-y') {
            $force = 1;
        }
        else {
            die "Unknown option: $arg\n" . $self->usage;
        }
    }

    my $def_path = $app->home->child($asset_dir, 'assetpack.def');

    # Overwrite check
    if (!$force && -f $def_path) {
        print "File '$asset_dir/assetpack.def' already exists. Overwrite? [y/N] ";
        my $answer = <STDIN>;
        chomp $answer;
        exit(0) unless $answer =~ /^y(es)?$/i;
    }

    # ── Phase 1: Scan plugins and merge defs ──

    my %bundles;
    my %seen;
    my @public_dirs;

    $app->log->debug("Starting asset merge from all plugins");

    for my $long (@{ $app->manager->load_order }) {
        my $entry = $app->manager->registry->{$long};
        my $short = $entry->{short_name};

        next unless $entry->{share_dir};

        my $share_dir = $entry->{share_dir};

        # Collect public dirs
        my $public_dir = $entry->{public_dir};
        if ($public_dir) {
            push @public_dirs, $public_dir->to_string;
        }

        # Look for assetpack.def
        my $def_file = $share_dir->child('assets', 'assetpack.def');
        next unless -f $def_file;

        $app->log->debug("$short Found assetpack.def");

        open my $fh, '<', $def_file or next;
        my $current_bundle;

        while (my $line = <$fh>) {
            chomp $line;
            next if $line =~ /^\s*$/ || $line =~ /^\s*#/;

            if ($line =~ /^\!\s*(\S+)/) {
                $current_bundle = $1;
                $bundles{$current_bundle} ||= [];
                next;
            }

            if ($line =~ /^\s*(<<?)\s*(.+)$/) {
                my ($op, $asset_path) = ($1, $2);
                my $key = "$current_bundle|$op|$asset_path";

                next if $seen{$key}++;

                # Normalize remote assets to single "<" so AssetPack renders them in dev mode
                $op = '<' if $asset_path =~ m{^https?://};

                push @{ $bundles{$current_bundle} }, "$op $asset_path";
            }
        }
        close $fh;
    }

    # ── Phase 2: Write merged assetpack.def ──

    my $merged_dsl = '';
    for my $bundle (sort keys %bundles) {
        next unless @{ $bundles{$bundle} };

        $merged_dsl .= "! $bundle\n";
        for my $line (@{ $bundles{$bundle} }) {
            $merged_dsl .= "$line\n";
        }
        $merged_dsl .= "\n";
    }

    if ($merged_dsl) {
        my $assets_dir = $app->home->child($asset_dir);
        $assets_dir->make_path unless -d $assets_dir;

        $def_path->spurt($merged_dsl);

        my $count = scalar keys %bundles;
        $app->log->debug("Merged assetpack.def written ($count bundles)");
    }
    else {
        say "No asset definitions found. Nothing written.";
        return;
    }

    # ── Phase 3: Get or create AssetPack instance ──

    my $asset;

    my @pipes = split /\s*,\s*/, ($config->{pipes} // 'Fetch,Sass,Css,Combine');
    $app->plugin('AssetPack' => {
                     pipes => \@pipes,
                 });
    $asset = $app->asset;

    # Point the store to the configured directory so it finds the def and writes there
    $asset->store->paths([$app->home->child($asset_dir)]);

    # Push store paths for asset resolution
    push @{ $asset->store->paths }, $app->home->child('public');
    push @{ $asset->store->paths }, $_ for @public_dirs;

    # ── Phase 4: Re-process with updated definitions ──

    say "Processing assets...";
    $asset->process();

    say "Assets generated successfully.";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Asset::Command::asset - Generate merged assetpack.def and process assets through AssetPack

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  $ myapp.pl asset generate
  $ myapp.pl asset generate -y

=head1 DESCRIPTION

Scans all Fondation plugins for C<share/assets/assetpack.def> files,
merges them into a single C<assets/assetpack.def>, and processes the
bundles through L<Mojolicious::Plugin::AssetPack>.

AssetPack serves assets dynamically through its route -- no C<app.css>
or C<app.js> files are written to disk.

=head1 NAME

Mojolicious::Plugin::Fondation::Asset::Command::asset - Generate asset bundles

=head1 SUBCOMMANDS

=head2 generate

Options:

  -y    Overwrite without confirmation prompt

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
