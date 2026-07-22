package Mojolicious::Plugin::Fondation::Menu::Command::menu;
$Mojolicious::Plugin::Fondation::Menu::Command::menu::VERSION = '0.02';
# ABSTRACT: Menu sync command — scan plugins for menus.json and insert entries

use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::File 'path';
use Mojo::JSON qw(decode_json);

has description => 'Sync menu entries from share/menus.json';
has usage       => sub ($self) {
    <<"USAGE";
Usage: APPLICATION menu COMMAND [OPTIONS]

  myapp.pl menu sync           Sync menu entries from all plugins
  myapp.pl menu sync -q        Quiet mode

USAGE
};

sub run ($self, @args) {
    my $app        = $self->app;
    my $subcommand = shift @args || '';

    for ($subcommand) {
        /^sync$/  and return $self->_sync($app, @args);
        die $self->usage;
    }
}

sub _sync ($self, $app, @args) {
    my $quiet = 0;
    for (@args) {
        $_ eq '-q' ? ($quiet = 1) : die "Unknown option: $_\n" . $self->usage;
    }

    # ── 1. Collect entries from all plugins in load order ───────────
    my $api      = $app->fondation;
    my $registry = $api->registry;
    my $manager  = $app->manager;
    my $load_order = $manager->load_order // [];
    my @all_entries;

    for my $long_name (@$load_order) {
        my $entry = $registry->{$long_name} or next;
        my $share = $entry->{share_dir} or next;
        my $menus_file = path($share, 'menus.json');
        next unless -f $menus_file;

        my $json = eval { decode_json($menus_file->slurp) };
        if ($@) {
            warn "Failed to parse $menus_file: $@\n";
            next;
        }

        next unless ref $json eq 'ARRAY';
        push @all_entries, @$json;
    }

    unless (@all_entries) {
        say "No menus found." unless $quiet;
        return;
    }

    say "Found " . scalar(@all_entries) . " menu entries across all plugins." unless $quiet;

    # ── 2. Build a native schema for synchronous DB access ───────────
    my $c  = $app->build_controller;
    my $be = eval { $c->backend_config };
    unless ($be) {
        say "No backend configured. Cannot sync menus." unless $quiet;
        return;
    }

    my $schema;
    eval {
        my $schema_class = $be->{schema_class};
        require Module::Runtime;
        Module::Runtime::require_module($schema_class);
        my %extra;
        $extra{quote_char} = $be->{quote_char} if $be->{quote_char};
        $schema = $schema_class->connect(
            $be->{dsn}, $be->{user}, $be->{pass},
            $be->{dbi_attrs} // {},
            \%extra,
        );
    };
    if ($@) {
        say "Failed to connect to database: $@" unless $quiet;
        return;
    }

    # ── 3. Ensure Menu source is registered ──────────────────────────
    eval { $schema->resultset('Menu') };
    if ($@) {
        say "Menu source not found. Skipping sync." unless $quiet;
        return;
    }

    my $rs    = $schema->resultset('Menu');
    my $guard = $schema->txn_scope_guard;
    my $count = 0;

    # ── 4. Split entries: roots first, then children ─────────────────
    my (@roots, @children);
    for my $entry (@all_entries) {
        if ($entry->{parent_title}) {
            push @children, $entry;
        } else {
            push @roots, $entry;
        }
    }

    # ── 5. Insert roots ──────────────────────────────────────────────
    for my $entry (@roots) {
        my $title = $entry->{title} or next;
        my $name  = $entry->{menu}  || 'left';

        my $exists = $rs->search({ title => $title, name => $name })->count;
        if ($exists) {
            say "  SKIP $name / $title (already exists)" unless $quiet;
            next;
        }

        my $order = $entry->{order};
        unless (defined $order) {
            $order = ($rs->search({
                parent_id => undef,
                name      => $name,
            })->get_column('sort_order')->max // -1) + 1;
        }

        $rs->create({
            title       => $title,
            link        => $entry->{link}        || '',
            icon        => $entry->{icon}        || '',
            icon_color  => $entry->{icon_color}  || '',
            name        => $name,
            condition   => $entry->{condition}   || '',
            sort_order  => $order,
            parent_id   => undef,
            open_tab    => $entry->{open_tab}    ? 1 : 0,
            view_in_menu => exists $entry->{view_in_menu}
                            ? ($entry->{view_in_menu} ? 1 : 0) : 1,
            description => $entry->{description} || '',
        });

        $count++;
        say "  ADD  $name / $title" unless $quiet;
    }

    # ── 6. Insert children ───────────────────────────────────────────
    for my $entry (@children) {
        my $title = $entry->{title} or next;
        my $name  = $entry->{menu}  || 'left';

        my $exists = $rs->search({ title => $title, name => $name })->count;
        if ($exists) {
            say "  SKIP $name / $title (already exists)" unless $quiet;
            next;
        }

        my $parent_title = $entry->{parent_title};
        my $parent = $rs->search({
            title => $parent_title,
            name  => $name,
        })->single;
        unless ($parent) {
            warn "Parent '$parent_title' not found in '$name' — skipping '$title'\n";
            next;
        }
        my $parent_id = $parent->id;

        my $order = $entry->{order};
        unless (defined $order) {
            $order = ($rs->search({
                parent_id => $parent_id,
                name      => $name,
            })->get_column('sort_order')->max // -1) + 1;
        }

        $rs->create({
            title       => $title,
            link        => $entry->{link}        || '',
            icon        => $entry->{icon}        || '',
            icon_color  => $entry->{icon_color}  || '',
            name        => $name,
            condition   => $entry->{condition}   || '',
            sort_order  => $order,
            parent_id   => $parent_id,
            open_tab    => $entry->{open_tab}    ? 1 : 0,
            view_in_menu => exists $entry->{view_in_menu}
                            ? ($entry->{view_in_menu} ? 1 : 0) : 1,
            description => $entry->{description} || '',
        });

        $count++;
        say "  ADD  $name / $title" unless $quiet;
    }

    $guard->commit;

    say "Synced $count new menu(s)." unless $quiet;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Menu::Command::menu - Menu sync command — scan plugins for menus.json and insert entries

=head1 VERSION

version 0.02

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
