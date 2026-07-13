package Mojolicious::Plugin::Fondation::Action::Static;
$Mojolicious::Plugin::Fondation::Action::Static::VERSION = '0.04';
# ABSTRACT: Registers public asset directories from plugin share directories

use Mojo::Base 'Mojolicious::Plugin::Fondation::Action::Base', -signatures;

use Mojolicious::Plugin::Fondation::Utils qw(share_relative);

sub after_load ($self, $long, $conf, $share_dir) {
    return unless $share_dir && -d $share_dir;

    my $public_dir = $share_dir->child('public');
    return unless -d $public_dir;

    my $manager = $self->manager;
    my $app     = $manager->app;

    # Add public directory to static file paths
    push @{$app->static->paths}, $public_dir->to_string;
    $self->log->debug("Added public path: " . share_relative($public_dir));

    # Store in registry for other consumers (e.g. Asset plugin)
    my $entry = $manager->registry->{$long};
    $entry->{public_dir} = $public_dir;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Action::Static - Registers public asset directories from plugin share directories

=head1 VERSION

version 0.04

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
