package Mojolicious::Plugin::Fondation::Controller::Debug;
$Mojolicious::Plugin::Fondation::Controller::Debug::VERSION = '0.01';
# ABSTRACT: Development debug endpoint showing the plugin registry

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub registry ($c) {
    $c->render_later;
    my $manager  = $c->app->manager;
    my $registry = $manager->registry;

    my $clean = {};
    for my $long (keys %$registry) {
        my $entry = {%{$registry->{$long}}};
        if (exists $entry->{instance}) {
            $entry->{instance} = 'bless( ' . ref($entry->{instance}) . ' )';
        }
        $clean->{$long} = $entry;
    }

    $c->stash(
        title        => 'Fondation Registry Debug',
        manager      => $manager,
        registry     => $clean,
        load_order   => $manager->load_order,
        fixture_sets => $manager->fixture_sets,
    );

    $c->render(template => 'debug/registry');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Controller::Debug - Development debug endpoint showing the plugin registry

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
