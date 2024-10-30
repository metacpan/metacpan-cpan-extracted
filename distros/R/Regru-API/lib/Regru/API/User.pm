package Regru::API::User;

# ABSTRACT: REG.API v2 user account management

use strict;
use warnings;
use Moo;
use namespace::autoclean;

our $VERSION = '0.053'; # VERSION
our $AUTHORITY = 'cpan:OLEG'; # AUTHORITY

with 'Regru::API::Role::Client';

has '+namespace' => (
    default => sub { 'user' },
);

sub available_methods {[qw(
    nop
    create
    get_statistics
    get_balance
)]}

__PACKAGE__->namespace_methods;
__PACKAGE__->meta->make_immutable;

1; # End of Regru::API::User

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::User - REG.API v2 user account management

=head1 VERSION

version 0.053

=head1 DESCRIPTION

REG.API account management methods such as create new user, fetch some statistics and deposit funds to an account.

=head1 ATTRIBUTES

=head2 namespace

Always returns the name of category: C<user>. For internal uses only.

=head1 REG.API METHODS

=head2 nop

For testing purposes. Scope: B<everyone>. Typical usage:

    $resp = $client->user->nop;

Returns success response.

More info at L<Account management: nop|https://www.reg.com/support/help/api2#user_nop>.

=head2 create

Creates a new user account. Scope: B<partners>. Typical usage:

    $resp = $client->user->create(
        # required fields
        user_login      => 'digory',
        user_password   => 'gof4iSewvy8aK5at',
        user_email      => 'digory.kirke@wardrobe.co.uk',
        user_country    => 'GB',

        # optional extra fields
        ...

        set_me_as_referer => 1,
    );

Answer will contains an C<user_id> field for newly created user account or error otherwise.

There are a lot of optional fields related to user account so check the documentation if you wish to use them.
More info at L<Account management: create|https://www.reg.com/support/help/api2#user_create>.

=head2 get_statistics

Fetch usage statistic for current account. Scope: B<clients>. Typical usage:

    $resp = $client->user->get_statistics(
        date_from => '2013-01-01',
        date_till => '2013-06-30',
    );

Parameters C<date_from> and C<date_till> are optional. Answer will contains a set of metrics such as number of active
domain names, number of domain names which are subject to renewal, number of folders, etc.

More info at L<Account management: get_statistics|https://www.reg.com/support/help/api2#user_get_statistics>.

=head2 get_balance

Shows a current user account balance. Scope: B<clients>. Typical usage:

    $resp = $client->user->get_balance(
        currency => 'EUR',
    );

Answer will contains a set of fields like amount of available funds, amount of a blocked funds. For resellers (partners)
will be shown amount of available credit additionally.

More info at L<Account management: get_balance|https://www.reg.com/support/help/api2#user_get_balance>.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

L<REG.API Account management|https://www.reg.com/support/help/api2#user_functions>

L<REG.API Common error codes|https://www.reg.com/support/help/api2#common_errors>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/regru/regru-api-perl/issues>

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
