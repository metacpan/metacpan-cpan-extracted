package Mojolicious::Plugin::Fondation::Group;
$Mojolicious::Plugin::Fondation::Group::VERSION = '0.01';
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use DBIx::Class::Relationship::ManyToMany::Async;

# ABSTRACT: Group management plugin for Fondation

sub fondation_meta {
    return {
        dependencies => [
            'Fondation::Model::DBIx::Async',
            'Fondation::MigrationDBIx',
            ],
        defaults => {
            title           => 'Group Management',
            openapi_exclude => ['UserGroup'],
            models          => {
                group => {
                    source  => 'Group',
                    backend => undef,  # must be set in app config
                },
                user_group => {
                    source  => 'UserGroup',
                    backend => undef,  # must be set in app config
                },
            },
        },
    };
}

sub register ($self, $app, $conf) {
    return $self;
}

sub fondation_finalyze ($self, $app, $long_name) {
    my $registry = $app->fondation->registry;

    # Only establish user↔group relation if User plugin is loaded
    if ($registry->{'Mojolicious::Plugin::Fondation::User'}) {
        # Underlying has_many / belongs_to
        Mojolicious::Plugin::Fondation::User::Schema::Result::User->has_many(
            'user_group',
            'Mojolicious::Plugin::Fondation::Group::Schema::Result::UserGroup',
            'user_id',
        );
        Mojolicious::Plugin::Fondation::Group::Schema::Result::UserGroup->belongs_to(
            'user',
            'Mojolicious::Plugin::Fondation::User::Schema::Result::User',
            { 'foreign.id' => 'self.user_id' },
        );

        many_to_many_async('Mojolicious::Plugin::Fondation::User::Schema::Result::User', 'groups', 'user_group', 'group');
        many_to_many_async('Mojolicious::Plugin::Fondation::Group::Schema::Result::Group', 'users',  'user_group', 'user');
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Group - Group management plugin for Fondation

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
