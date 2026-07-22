package Mojolicious::Plugin::Fondation::Menu::Helpers;
$Mojolicious::Plugin::Fondation::Menu::Helpers::VERSION = '0.02';
# ABSTRACT: Menu helpers — server-side cache, rendering, breadcrumb

use strict;
use warnings;

use Mojo::Base -strict, -signatures;

# ── Register all helpers ────────────────────────────────────────────────

sub register_all ($class, $app) {

    # ── _menus_cache ──────────────────────────────────────────────────
    # Returns the server-side cache hashref (lazy, shared across users)
    my $_menus_cache;
    my $_menus_loaded = 0;

    my $_get_cache = sub {
        return $_menus_cache if $_menus_loaded;
        return undef;
    };

    my $_invalidate_cache = sub {
        $_menus_loaded = 0;
        undef $_menus_cache;
    };

    my $_ensure_cache;

    # ── breadcrumb ─────────────────────────────────────────────────────
    $app->helper(breadcrumb => sub ($c) {
        $_ensure_cache->($c);
        my $menus = $_get_cache->();
        return [] unless $menus && $menus->{_by_path};

        my $path = $c->req->url->path->to_abs_string // '/';
        $path = "/$path" unless $path =~ m|^/|;

        return [] if $path eq '/';

        my $menu = $menus->{_by_path}{$path};
        unless ($menu) {
            $menu = _find_menu_by_path_prefix($path, $menus->{_by_path});
        }

        return [] unless $menu;

        my @trail = ($menu);
        while ($menu->{parent_id}) {
            $menu = $menus->{_by_id}{$menu->{parent_id}};
            last unless $menu;
            unshift @trail, $menu;
        }

        return \@trail;
    });

    # ── menu_by_name ────────────────────────────────────────────────────
    $app->helper(menu_by_name => sub ($c, $name) {
        $_ensure_cache->($c);
        my $menus = $_get_cache->();
        return [] unless $menus && $menus->{_by_name};
        return $menus->{_by_name}{$name} // [];
    });

    # ── menu_by_id ──────────────────────────────────────────────────────
    $app->helper(menu_by_id => sub ($c, $id) {
        my $menus = $_get_cache->();
        return undef unless $menus && $menus->{_by_id};
        return $menus->{_by_id}{$id};
    });

    # ── menus ───────────────────────────────────────────────────────────
    $app->helper(menus => sub ($c, $init = undef) {
        my $cache = $_get_cache->();
        return $cache if $cache && !$init;
        return _build_menus_cache($c, \$_menus_cache, \$_menus_loaded);
    });

    # ── render_menu ──────────────────────────────────────────────
    $app->helper(render_menu => sub ($c, $name) {
        my $menus = $c->menu_by_name($name);
        return '' unless @$menus;
        return $c->render_to_string(
            template => 'menu/navbar',
            menus    => $menus,
        );
    });

    # ── check_menu_condition ────────────────────────────────────────────
    $app->helper(check_menu_condition => sub ($c, $condition) {
        return 1 unless defined $condition && length $condition;

        # Support comma-separated compound conditions (AND logic)
        for my $cond (split /\s*,\s*/, $condition) {
            return 0 unless _check_single_menu_condition($c, $cond);
        }
        return 1;
    });

    # ── render_menu_breadcrumb ──────────────────────────────────────────
    $app->helper(render_menu_breadcrumb => sub ($c) {
        my $trail = $c->breadcrumb;
        return '' unless @$trail;
        return $c->render_to_string(
            template => 'menu/breadcrumb',
            trail    => $trail,
        );
    });

    # ── menu_cache_invalidate ───────────────────────────────────────────
    # Called by CRUD operations to clear the cache.
    $app->helper(menu_cache_invalidate => sub { $_invalidate_cache->() });

    # ── _ensure_cache ───────────────────────────────────────────────────
    # Lazy-init cache on first access (non-blocking, no hook needed).
    $_ensure_cache = sub ($c) {
        return if $_menus_loaded;
        _build_menus_cache($c, \$_menus_cache, \$_menus_loaded);
    };
}

# ══════════════════════════════════════════════════════════════════════════
# Internal
# ══════════════════════════════════════════════════════════════════════════

# Check a single menu condition (no comma splitting).
sub _check_single_menu_condition ($c, $cond) {
    if ($cond eq 'auth') {
        return $c->has_helper('is_user_authenticated')
            ? $c->is_user_authenticated : 0;
    }
    if ($cond eq '!auth') {
        return $c->has_helper('is_user_authenticated')
            ? !$c->is_user_authenticated : 1;
    }
    if ($cond =~ /^group:(.+)$/) {
        return $c->check_group($1);
    }
    if ($cond =~ /^perm:(.+)$/) {
        return $c->check_perm($1);
    }
    if ($cond =~ /^mode:!(.+)$/) {
        return $c->app->mode ne $1;
    }
    if ($cond =~ /^mode:(.+)$/) {
        return $c->app->mode eq $1;
    }
    $c->app->log->warn("Unknown menu condition format: $cond");
    return 0;
}

sub _build_menus_cache ($c, $cache_ref, $loaded_ref) {
    my $schema = $c->schema;
    return undef unless $schema;

    my $results = $schema->await(
        $schema->resultset('Menu')->search(
            undef,
            { order_by => { -asc => 'sort_order' } },
        )->all
    );

    my @plain;
    for my $m (@$results) {
        push @plain, {
            id          => $m->id,
            title       => $m->title,
            link        => $m->link,
            icon        => $m->icon,
            icon_color  => $m->icon_color,
            name        => $m->name,
            condition   => $m->condition,
            sort_order  => $m->sort_order,
            parent_id   => $m->parent_id,
            open_tab    => $m->open_tab,
            view_in_menu => $m->view_in_menu,
            description => $m->description,
            children    => [],
        };
    }

    my %by_id;
    for my $m (@plain) {
        $by_id{$m->{id}} = $m;
    }
    for my $m (@plain) {
        if ($m->{parent_id} && exists $by_id{$m->{parent_id}}) {
            push @{$by_id{$m->{parent_id}}{children}}, $m;
        }
    }

    my %by_name;
    for my $m (@plain) {
        next if $m->{parent_id} && exists $by_id{$m->{parent_id}};
        push @{$by_name{$m->{name}}}, $m;
    }

    my %by_path;
    for my $m (@plain) {
        next unless defined $m->{link} && length $m->{link};
        my $link = $m->{link};
        $link = "/$link" unless $link =~ m|^/|;
        $by_path{$link} = $m;
    }

    my $cache = {
        _by_name => \%by_name,
        _by_id   => \%by_id,
        _by_path => \%by_path,
    };

    $$cache_ref  = $cache;
    $$loaded_ref = 1;
    return $cache;
}

sub _find_menu_by_path_prefix ($path, $by_path) {
    while (length $path > 1) {
        $path =~ s|/[^/]*$||;
        $path = '/' unless length $path;
        return $by_path->{$path} if exists $by_path->{$path};
    }
    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Menu::Helpers - Menu helpers — server-side cache, rendering, breadcrumb

=head1 VERSION

version 0.02

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
