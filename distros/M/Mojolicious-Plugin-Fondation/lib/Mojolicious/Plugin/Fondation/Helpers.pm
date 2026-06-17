package Mojolicious::Plugin::Fondation::Helpers;
# ABSTRACT: All Fondation helpers in one place -- keeps Fondation.pm minimal
$Mojolicious::Plugin::Fondation::Helpers::VERSION = '0.02';
use Mojo::Base -base, -signatures;
use Mojo::ByteStream 'b';

sub register ($class, $app, $manager) {

    # ═══════════════════════════════════════════════════════════════════════
    # ── Core identity ──
    # ═══════════════════════════════════════════════════════════════════════
    $app->helper(manager => sub { $manager });

    # Stable public API (recommended over direct manager access)
    $app->helper(fondation => sub { $manager->api });

    # ═══════════════════════════════════════════════════════════════════════
    # ── Fallback helpers -- overridden by specialized plugins ──
    # Must be registered BEFORE load_plugin_recursive so plugins can override.
    # ═══════════════════════════════════════════════════════════════════════

    # Overridden by I18N-like plugins
    $app->helper(l => sub { $_[1] });

    # Fallback i18n_js -- injected by layout before app JS.
    # Identity function when I18N absent; overridden by I18N-like plugins.
    $app->helper(i18n_js => sub ($c) {
        return Mojo::ByteStream->new(
            q{<script>window.l=function(k){return k;};</script>}
        );
    });

    # Overridden by a Notification plugin
    $app->helper(notify_user => sub { Mojo::Promise->resolve() });

    # Overridden by a Authorization plugin -- permissive fallback (allow all)
    $app->helper(check_group => sub { 1 });
    $app->helper(check_perm  => sub { 1 });

    # ═══════════════════════════════════════════════════════════════════════
    # ── Route conditions ──
    # ── check_perm/check_group are no-ops above until Authorization plugin
    # ── overrides them.
    # ═══════════════════════════════════════════════════════════════════════

    $app->routes->add_condition('fondation.perm' => sub {
        my ($route, $c, $captures, $perm) = @_;
        return 1 if $c->check_perm($perm);
        $c->render(text => 'Forbidden', status => 403);
        return undef;
    });

    $app->routes->add_condition('fondation.group' => sub {
        my ($route, $c, $captures, $group) = @_;
        return 1 if $c->check_group($group);
        $c->render(text => 'Forbidden', status => 403);
        return undef;
    });


    # ═══════════════════════════════════════════════════════════════════════
    # ── Real helpers (not no-ops) ──
    # ═══════════════════════════════════════════════════════════════════════

    # Check whether a helper exists (Mojo helpers are not visible via $c->can).
    $app->helper(has_helper => sub ($c, $name) {
        return exists $c->app->renderer->helpers->{$name};
    });


    # ═══════════════════════════════════════════════════════════════════════
    # ── Zone system ──
    # ═══════════════════════════════════════════════════════════════════════

    $app->helper(render_zone_type => sub ($c, $type, $zone) {
        my $manager = $c->app->manager;
        my $output  = '';

        for my $long (@{$manager->load_order}) {
            my $entry = $manager->registry->{$long};
            next unless $entry;

            my $files = $entry->{zones}{$type}{$zone} // [];
            next unless @$files;

            if ($type eq 'html') {
                for my $template (@$files) {
                    $output .= $c->render_to_string(
                        template => $template,
                        layout   => undef,
                    );
                }
            }
            else {
                for my $content (@$files) {
                    $output .= $content;
                }
            }
        }

        return $output;
    });

    $app->helper(render_zone => sub ($c, $zone) {
        return $c->render_zone_type('html', $zone);
    });

    $app->helper(render_zone_js => sub ($c, $zone) {
        return $c->render_zone_type('js', $zone);
    });

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Helpers - All Fondation helpers in one place -- keeps Fondation.pm minimal

=head1 VERSION

version 0.02

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
