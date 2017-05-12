package Monitis::Contacts;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add {
    my ($self, @params) = @_;

    my @mandatory = qw/firstName lastName account contactType timezone/;
    my @optional =
      qw/group sendDailyReport sendWeeklyReport sendMonthlyReport portable country textType/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addContact' => $params);
}

sub edit {
    my ($self, @params) = @_;

    my @mandatory = qw/contactId/;
    my @optional =
      qw/firstName lastName account contactType timezone sendDailyReport sendWeeklyReport sendMonthlyReport portable code country textType/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('editContact' => $params);
}

sub delete {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/contactId account contactType/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    unless (@$params) {
        Carp::croak(
            "One of optional parameters required for deleting contact");
    }

    return $self->api_post('deleteContact' => $params);
}

sub confirm {
    my ($self, @params) = @_;

    my @mandatory = qw/contactId confirmationKey/;

    my $params = $self->prepare_params(\@params, \@mandatory);

    return $self->api_post('confirmContact' => $params);
}

sub activate {
    my ($self, @params) = @_;

    my @mandatory = qw/contactId/;

    my $params = $self->prepare_params(\@params, \@mandatory);

    return $self->api_post('contactActivate' => $params);
}

sub deactivate {
    my ($self, @params) = @_;

    my @mandatory = qw/contactId/;

    my $params = $self->prepare_params(\@params, \@mandatory);

    return $self->api_post('contactDeactivate' => $params);
}

sub get {
    my $self = shift;

    return $self->api_get('contactsList');
}

sub get_groups {
    my $self = shift;

    return $self->api_get('contactGroupList');
}

sub get_recent_alerts {
    my ($self, @params) = @_;

    my @mandatory;
    my @optional = qw/timezone startDate endDate limit/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('recentAlerts' => $params);
}
__END__

=head1 NAME

Monitis::Contacts - Contacts manipulation

=head1 SYNOPSIS

    use Monitis::Contacts;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::Contacts> implements following attributes:

=head1 METHODS

L<Monitis::Contacts> implements following methods:

=head2 add

    my $response = $api->contacts->add(
        firstName   => 'John',
        lastName    => 'Smith',
        account     => '1234567',
        contactType => 3,           # ICQ
        timezone    => 300
    );

Add new contact.

Mandatory parameters:

    firstName lastName account contactType timezone

Optional parameters:

    group sendDailyReport sendWeeklyReport sendMonthlyReport portable country textType

Normal response is:

    {   "status" => "ok",
        "data"   => {
            "confirmationKey" => "1022312835020242188844937884154552",
            "contactId"       => 10223
        }
    }

=head2 edit

    my $response = $api->contacts->edit(
        contactId => 10223,
        firstName => 'Ivan'
    );

Edit contact details.

Mandatory parameters:

    contactId

Optional parameters:

    firstName lastName account contactType timezone sendDailyReport
    sendWeeklyReport sendMonthlyReport portable code country textType

Normal response is:

    {   "status" => "ok",
        "data"   => {"confirmationKey" => "1022312837120242188844937884195552"}

    }

=head2 delete

    my $response = $api->contacts->delete(contactId => 10223);

Delete contact.

Mandatory parameters:

    One of optional parameters required to be specified.

Optional parameters:

    contactId account contactType

Normal response is:

    {"status" => "ok"}

=head2 confirm

    my $response =
      $api->contacts->confirm(contactId => 10223, confirmationKey => $key);

Confirm contact.

Mandatory parameters:

    contactId confirmationKey

Normal response is:

    {"status" => "ok"}

=head2 activate

    my $response =
      $api->contacts->activate(contactId => 10223);

Activate contact.

Mandatory parameters:

    contactId

Normal response is:

    {"status" => "ok"}

=head2 deactivate

    my $response =
      $api->contacts->deactivate(contactId => 10223);

Activate contact.

Mandatory parameters:

    contactId

Normal response is:

    {"status" => "ok"}

=head2 get

    my $response = $api->contacts->get;

Get all contacts.

Normal response is:

    [   {   "contactId"        => 3549,
            "name"             => "John Smith",
            "contactType"      => "Email",
            "contactAccount"   => "j_s@gmail.com",
            "timezone"         => 300,
            "portable"         => false,
            "activeFlag"       => 1,
            "textType"         => 0,
            "confirmationFlag" => 1,
            "country"          => "USA"
        },

        # ...
    ]

=head2 get_groups

    my $response = $api->contacts->get_groups;

Get all groups.

Normal response is:

    [   {   "id"         => 681,
            "activeFlag" => 1,
            "name"       => "Monitoring Team"
        },

        # ...
    ]

=head2 get_recent_alerts

    my $response =
      $api->contacts->get_recent_alerts(startDate => $start, endDate => $end);

Get all recent alerts.

Optional parameters:

    timezone startDate endDate limit

Normal response is:

    {   "status" => "ok",
        "data"   => [
            {   "dataType"   => "External Monitor",
                "recDate"    => "8 May 2011 07 => 09 => 59 GMT",
                "dataId"     => 36963,
                "failDate"   => "8 May 2011 07 => 04 => 58 GMT",
                "dataTypeId" => 0,
                "contacts"   => "someAccount@gmail.com",
                "dataName"   => "api_dns"
            },

            # ...
        ]
    }


=head1 SEE ALSO

L<Monitis>

Official API page: L<http://monitis.com/api/api.html#addContact>


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

