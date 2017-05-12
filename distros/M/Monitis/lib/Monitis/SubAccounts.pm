package Monitis::SubAccounts;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add {
    my ($self, @params) = @_;

    my @mandatory = qw/firstName lastName email password group/;

    my $params = $self->prepare_params(\@params, \@mandatory);

    return $self->api_post('addSubAccount' => $params);
}

sub get {
    my $self = shift;

    return $self->api_get('subAccounts');
}

sub pages {
    my $self = shift;

    return $self->api_get('subAccountPages');
}

sub add_pages {
    my ($self, @params) = @_;

    my @mandatory = qw/userId pageNames/;

    my $params = $self->prepare_params(\@params, \@mandatory);

    return $self->api_post('addPagesToSubAccount' => $params);
}

sub delete_pages {
    my ($self, @params) = @_;

    my @mandatory = qw/userId pageNames/;
    my $params = $self->prepare_params(\@params, \@mandatory);

    return $self->api_post('deletePagesFromSubAccount' => $params);
}

sub delete {
    my ($self, @params) = @_;

    my @mandatory = qw/userId/;
    my $params = $self->prepare_params(\@params, \@mandatory);

    return $self->api_post('deleteSubAccount' => $params);
}


1;

__END__

=head1 NAME

Monitis::SubAccounts - Sub-accounts manipulation

=head1 SYNOPSIS

    use Monitis::SubAccounts;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis> implements following attributes:

=head1 METHODS

L<Monitis> implements following methods:

=head2 add

    my $response = $api->sub_accounts->add(
        firstName => 'John',
        lastName  => 'Smith',
        email     => 'john@smith.com',
        password  => 'test password',
        group     => 'test group'
    );

Add new sub account.

Mandatory parameters are:

    firstName lastName email password group

Normal response is:

    {   status => 'ok',
        data   => {userId => 12360}
    }

=head2 get

    my $response = $api->sub_accounts->get;

Returns all subaccount of your account. Normal response is:

    [   {   "id"        => 12360,
            "lastName"  => "Smith",
            "account"   => "john@smith.com",
            "firstName" => "John",
            "userkey"   => "80PMYRH3E8B7P5FMI6RDVJ84C1"
        },
        #...
    ]

=head2 pages

    my $response = $api->sub_accounts->pages;

Returns all subaccount's pages.

Normal response is:

    [   {   "id"    => 12360,
            "pages" => [
                "reports",
                "snapshots",

                # ...
            ],
            "account" => 'sfs@ss.com'
        },
    ]

=head2 add_pages

    my $response = $api->sub_accounts->add_pages(
        userId    => 12360,
        pageNames => 'Page One;Page Two'
    );

Add pages to subaccount.

Mandatory parameters are:

    userId pageNames

Normal response is:

    {"status" => "ok"}

=head2 delete_pages

    my $response = $api->sub_accounts->delete_pages(
        userId    => 12360,
        pageNames => 'Page One;Page Two'
    )

Delete pages from subaccount.

Mandatory parameters are:

    userId pageNames

Normal response is:

    {"status" => "ok"}

=head2 delete

    my $response = $api->sub_accounts->delete(userId => 12360)

Delete subaccount.

Mandatory parameters are:

    userId

Normal response is:

    {"status" => "ok"}


=head1 SEE ALSO

L<Monitis>

Official API page: L<http://monitis.com/api/api.html#addSubAccount>


=head1 AUTHOR

Yaroslav Korshak  C<< <ykorshak@gmail.com> >>
Alexandr Babenko  C<< <foxcool@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006-2011, Monitis Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
