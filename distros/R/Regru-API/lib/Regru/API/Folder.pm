package Regru::API::Folder;

# ABSTRACT: REG.API v2 user folders management

use strict;
use warnings;
use Moo;
use namespace::autoclean;

our $VERSION = '0.046'; # VERSION
our $AUTHORITY = 'cpan:IMAGO'; # AUTHORITY

with 'Regru::API::Role::Client';

has '+namespace' => (
    default => sub { 'folder' },
);

sub available_methods {[qw(
    nop
    create
    remove
    rename
    get_services
    add_services
    remove_services
    replace_services
    move_services
)]}

__PACKAGE__->namespace_methods;
__PACKAGE__->meta->make_immutable;

1; # End of Regru::API::Folder

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Folder - REG.API v2 user folders management

=head1 VERSION

version 0.046

=head1 DESCRIPTION

REG.API folders management methods such as create/remove/rename folders, get/put services linked to and others.

=head1 ATTRIBUTES

=head2 namespace

Always returns the name of category: C<folder>. For internal uses only.

=head1 REG.API METHODS

=head2 nop

For testing purposes. Scope: B<everyone>. Typical usage:

    $resp = $client->folder->nop(
        folder_name => 'our_folder',
    );

Returns success response.

More info at L<Folder management: nop|https://www.reg.com/support/help/api2#folder_nop>.

=head2 create

Creates a folder. Scope: B<clients>. Typical usage:

    $resp = $client->folder->create(
        folder_name => 'vehicles',
    );

Returns success response if folder was created or error otherwise.

More info at L<Folder management: create|https://www.reg.com/support/help/api2#folder_create>.

=head2 remove

Deletes an existing folder. Scope: B<clients>. Typical usage:

    $resp = $client->folder->remove(
        folder_id => 674908,
    );

Returns success response if folder was deleted or error otherwise.

More info at L<Folder management: remove|https://www.reg.com/support/help/api2#folder_remove>.

=head2 rename

Renames an existing forder. Scope: B<clients>. Typical usage:

    $resp = $client->folder->rename(
        folder_name     => 'stuff',
        new_folder_name => 'items',
    );

Returns success response if folder was renamed or error otherwise.

More info at L<Folder management: rename|https://www.reg.com/support/help/api2#folder_rename>.

=head2 get_services

Gets services linked to folder. Scope: B<clients>. Typical usage:

    $resp = $client->folder->get_services(
        folder_id => 389765,
    );

A success answer will contains a C<folder_content> with a list of services (domain names, hosting related items, etc) linked
to requested folder.

More info at L<Folder management: get_services|https://www.reg.com/support/help/api2#folder_get_services>.

=head2 add_services

"Puts" services to folder. Scope: B<clients>. Typical usage:

    $resp = $client->folder->add_services(
        folder_name => 'vehicles',
        services => [
            { domain_name => 'crucible.co.uk' },
            { domain_name => 'ss-madame-de-pompadour.ru' },
        ],
        return_folder_contents => 1,
    );

A successful answer will contains a C<services> field with a list of services that was linked to the specified folder
and result for each of them. Additionally might be returned a C<folder_content> field.

More info at L<Folder management: add_services|https://www.reg.com/support/help/api2#folder_add_services>.

=head2 remove_services

"Deletes" services from folder. Scope: B<clients>. Typical usage:

    $resp = $client->folder->remove_services(
        folder_name => 'vehicles',
        services => [
            { domain_name => 'bow-tie.com' },
        ],
    );

A successful answer will contains a C<services> field with a list of services that was unlinked to the specified folder
and result for each of them. Additionally might be returned a C<folder_content> field.

More info at L<Folder management: remove_services|https://www.reg.com/support/help/api2#folder_remove_services>.

=head2 replace_services

"Replaces" services with a new set of services. Scope: B<clients>. Typical usage:

    $resp = $client->folder->replace_services(
        folder_name => 'items',
        services => [
            { domain_name => 'bow-tie.com' },
            { service_id => 188650 },
            { service_id => 239076 },
        ],
    );

A successful answer will contains a C<services> field with a list of services that was linked to the specified folder
and result for each of them. Additionally might be returned a C<folder_content> field.

More info at L<Folder management: replace_services|https://www.reg.com/support/help/api2#folder_replace_services>.

=head2 move_services

"Transfers" services between folders. Scope: B<clients>. Typical usage:

    $resp = $client->folder->move_services(
        folder_name     => 'vehicles',
        new_folder_name => 'items',
        services => [
            { domain_name => 'bow-tie.cz' },
            { domain_name => 'hallucinogenic-lipstick.xxx' },
            { service_id => 783908 },
        ],
    );

A successful answer will contains a C<services> field with a list of services that was linked to the specified folder
and result for each of them. Additionally might be returned a C<folder_content> field with a contents of a destination folder.

More info at L<Folder management: move_services|https://www.reg.com/support/help/api2#folder_move_services>.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

L<REG.API Folders management|https://www.reg.com/support/help/api2#folder_functions>

L<REG.API Common error codes|https://www.reg.com/support/help/api2#common_errors>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/regru/regru-api-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Polina Shubina <shubina@reg.ru>

=item *

Anton Gerasimov <a.gerasimov@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
