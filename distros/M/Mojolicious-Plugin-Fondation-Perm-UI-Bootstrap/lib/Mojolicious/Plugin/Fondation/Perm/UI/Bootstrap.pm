package Mojolicious::Plugin::Fondation::Perm::UI::Bootstrap;
$Mojolicious::Plugin::Fondation::Perm::UI::Bootstrap::VERSION = '0.01';
# ABSTRACT: Web UI extension for Fondation::Perm — injects perm checkboxes into group forms

use Mojo::Base 'Mojolicious::Plugin', -signatures;


sub fondation_meta {
    return {
        dependencies => ['Fondation::Perm', 'Fondation::Layout::Bootstrap'],
        defaults     => {
            title => 'Permission Management UI',
        },
    };
}

sub register ($self, $app, $conf) {

    $app->routes->get('/perms')
      ->requires('fondation.perm' => 'perm_list')
      ->to(
        controller => 'Perm',
        action     => 'index'
    );

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Perm::UI::Bootstrap - Web UI extension for Fondation::Perm — injects perm checkboxes into group forms

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  # myapp.conf
  'Mojolicious::Plugin::Fondation::Perm::UI::Bootstrap' => {};

=head1 DESCRIPTION

Injects permission checkboxes into the group add/edit modal via Fondation
zones (C<group/add>). Provides C<loadPerms()> and C<collectPermAssignments()>
JavaScript functions consumed by C<DatatableGroup.js>.

=head1 ZONES

=head2 group/add

=over

=item C<html/group/add/perms.html.ep>

Bootstrap 5 checkboxes listing all available permissions, hidden by default,
shown by C<loadPerms()>.

=item C<js/group/add/perms.js.ep>

Two functions:

=over

=item C<loadPerms(group)>

Fetches all permissions via C<GET /api/perm>, renders checkboxes, and pre-checks
those the group already has (from C<group.perms>).

=item C<collectPermAssignments()>

Returns an array of checked permission IDs — called by C<validateGroupForm()>
in C<DatatableGroup.js> before save.

=back

=back

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
