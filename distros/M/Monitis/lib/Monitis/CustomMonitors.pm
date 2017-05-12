package Monitis::CustomMonitors;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub api_url {'http://www.monitis.com/customMonitorApi'}

sub add {
    my ($self, @params) = @_;

    my @mandatory = qw/name tag resultParams/;
    my @optional  = qw/monitorParams/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addMonitor' => $params);
}

sub edit {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId name tag/;
    my @optional  = qw/monitorParams/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('editMonitor' => $params);
}

sub get {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('getMonitors' => $params);
}

sub get_info {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId/;
    my @optional  = qw/excludeHidden/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('getMonitorInfo' => $params);
}

sub add_results {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId checktime results/;
    my @optional  = ();

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addResult' => $params);
}

sub get_results {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId day month year/;
    my @optional  = qw/timezone/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('getMonitorResults' => $params);
}

sub delete {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('deleteMonitor' => $params);
}

__END__

=head1 NAME

Monitis::CustomMonitors - Custom monitors manipulation

=head1 SYNOPSIS

    use Monitis::CustomMonitors;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::CustomMonitors> implements following attributes:

=head2 api_url

API url for Custom Monitors: http://www.monitis.com/customMonitorApi

=head1 METHODS

L<Monitis::CustomMonitors> implements following methods:

=head2 add

    my $response = $api->custom_monitors->add(
        resultParams => 'position:Position:N/A:2;difference:Difference:N/A:3',
        name     => 'test from api',
        tag      => 'test'
    );

Create monitor.

Mandatory parameters:

    agentkey name tag

Optional parameters:

    monitorParams

Normal response is:

    {   "data"   => 922,
        "status" => "ok"
    }

=head2 edit

    my $response = $api->custom_monitors->edit(
        monitorId  => 922,
        name    => 'test from api',
        tag     => 'test'
    );

Edit monitor.

Mandatory parameters:

    monitorId name tag

Optional parameters:

    monitorParams

Normal response is:

    {   "data"   => null,
        "status" => "ok"
    }

=head2 get

    my $response = $api->load_average->get;

Get monitors list.

Optional parameters:

    tag

Response:

    [   {   "tag"  => "test",
            "name" => "simple_custom_monitor",
            "id"   => "56"
        },

        # ...
    ]

=head2 get_info

    my $response = $api->custom_monitors->get_info(monitorId => 922);

Get monitor details.

Mandatory parameters:

    monitorId

Optional parameters:

    excludeHidden

Response:

    See L<http://monitis.com/api/api.html#getCustomMonitorInfo>

=head2 add_results

    my $response = $api->custom_monitors->add_results(
        monitorId => 922,
        checktime => time,
        results   => 'position:3;time:1'
    );

Add monitor results.

Mandatory parameters:

    monitorId checktime results

Response:

    {   "data"   => null,
        "status" => "ok"
    }

=head2 get_results

    my $response = $api->custom_monitors->get_results(
        monitorId => 922,
        day       => 1,
        month     => 5,
        year      => 2011
    );

Get monitor results.

Mandatory parameters:

    monitorId day month year

Optional parameters:

    timezone

Response:

    See L<http://monitis.com/api/api.html#getCustomMonitorResults>

=head2 delete

    my $response = $api->custom_monitors->delete(monitorId => 922);

Delete monitor.

Response:

    {   "data"   => null,
        "status" => "ok"
    }


=head1 SEE ALSO

L<Monitis>

Official API page: L<http://monitis.com/api/api.html#addCustomMonitor>


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
