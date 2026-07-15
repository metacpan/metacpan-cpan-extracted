package Mojolicious::Plugin::Fondation::User::UI::Bootstrap;
$Mojolicious::Plugin::Fondation::User::UI::Bootstrap::VERSION = '0.02';
use Mojo::Base 'Mojolicious::Plugin', -signatures;

# ABSTRACT: Web UI for Fondation::User — templates, assets, and i18n


sub fondation_meta {
    return {
        dependencies => ['Fondation::User', 'Fondation::Layout::Bootstrap', 'Fondation::OpenAPI'],
        defaults     => {
            title => 'User Management',
        },
    };
}

sub register ($self, $app, $conf) {

    $app->routes->get('/users')
      ->requires('fondation.perm' => 'user_list')
      ->to(
        controller => 'User',
        action     => 'index'
    );

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::User::UI::Bootstrap - Web UI for Fondation::User — templates, assets, and i18n

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # myapp.conf
  'Fondation::User::UI::Bootstrap' => {};

=head1 DESCRIPTION

Fondation::User::UI::Bootstrap provides the web interface for user management
in Fondation applications. It includes templates, assets, translations, and
routes for listing, creating, editing, and deleting users.

The plugin registers a single route C<GET /users> which requires the
C<fondation.perm =E<gt> user_list> condition. All other user CRUD operations
are handled by the generic REST actions provided by L<Fondation::User> via
L<Mojolicious::Plugin::Fondation::Action::REST>.

=head2 Dependencies

This plugin requires L<Fondation::User> and L<Fondation::Layout::Bootstrap>
to be loaded.

=head1 NAME

Mojolicious::Plugin::Fondation::User::UI::Bootstrap — Bootstrap 5 web UI for Fondation::User

=head1 VERSION

version 0.01

=head1 ROUTES

=head2 GET /users

=over

=item Condition: C<fondation.perm =E<gt> user_list>

=item Controller: C<User>

=item Action: C<index>

=back

Renders the user management page with a Bootstrap 5 DataTable listing all
users. The table supports inline editing, role/group assignment, and
activation/deactivation via modal dialogs provided by the plugin's templates
and JavaScript assets.

=head1 CONFIGURATION

  'Fondation::User::UI::Bootstrap' => {
      title => 'User Management',
  };

=over

=item C<title> — page title displayed in the UI. Defaults to C<User Management>.

=back

=head1 RESOURCES

The plugin ships with:

=over

=item C<share/templates/> — EP templates for user listing and modals

=item C<share/public/> — JavaScript modules (C<DatatableUser.js>) for client-side DataTable initialization

=item C<share/translations/> — i18n lexicons (en, fr)

=back

=head1 SEE ALSO

=over

=item L<Mojolicious::Plugin::Fondation::User> — the user management engine

=item L<Mojolicious::Plugin::Fondation::Layout::Bootstrap> — Bootstrap 5 layout

=item L<Mojolicious::Plugin::Fondation::Action::REST> — generic REST actions

=back

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
