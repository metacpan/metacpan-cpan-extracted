package Monitis::Drive;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add {
    my ($self, @params) = @_;

    my @mandatory = qw/agentkey driveLetter freeLimit name tag/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addDriveMonitor' => $params);
}

sub edit {
    my ($self, @params) = @_;

    my @mandatory = qw/testId freeLimit name tag/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('editDriveMonitor' => $params);
}

sub get {
    my ($self, @params) = @_;

    my @mandatory = qw/agentId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('agentDrives' => $params);
}

sub get_info {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('driveInfo' => $params);
}

sub get_results {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId day month year/;
    my @optional  = qw/timezone/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('driveResult' => $params);
}

sub get_top_results {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/timezoneoffset limit tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('topdrive' => $params);
}

__END__

=head1 NAME

Monitis::Drive - Predefined internal drive monitors manipulation

=head1 SYNOPSIS

    use Monitis::Drive;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::Drive> implements following attributes:

=head1 METHODS

L<Monitis::Drive> implements following methods:

=head2 add

    my $response = $api->drive->add(
        agentkey    => 'window_test_agent',
        driveLetter => 'C',
        freeLimit   => 50,
        name        => 'drive test',
        tag         => 'tests from api'
    );

Create monitor.

Mandatory parameters:

    agentkey driveLetter freeLimit name tag

Normal response is:

    {   "data"   => {"testId" => 922},
        "status" => "ok"
    }

=head2 edit

    my $response = $api->drive->edit(
        testId      => 922,
        name        => 'new test',
        tag         => 'test',
        driveLetter => 'C',
        freeLimit   => 1000,
    );

Edit monitor.

Mandatory parameters:

    testId driveLetter freeLimit name tag

Normal response is:

    {"status" => "ok"}

=head2 get

    my $response = $api->drive->get(agentId => 922);

Get monitor details.

Mandatory parameters:

    agentId

Response:

    See L<http://monitis.com/api/api.html#getDriveMonitors>

=head2 get_info

    my $response = $api->drive->get_info(monitorId => 922);

Get monitor info.

Mandatory parameters:

    monitorId

Response:

    See L<http://monitis.com/api/api.html#getDriveMonitorInfo>

=head2 get_results

    my $response = $api->drive->get_results(
        monitorId => 922,
        day       => 1,
        month     => 5,
        year      => 2011
    );

Get monitor result.

Mandatory parameters:

    agentId day month year

Optional parameters:

    timezone

Normal response is:

    [   {   "time"      => "00 => 04",
            "freeSpace" => 37.7078,
            "usedSpace" => 13.678097,
            "status"    => "OK"
        },

        # ...
    ]

=head2 get_top_results

    my $response = $api->drive->get_top_results;

Get monitor top results.

Optional parameters:

    timezoneoffset limit tag

Normal response is:

    {   "tags" => [
            "Default",    # ...
        ],
        "tests" => [
            {   "id"            => 4645,
                "testName"      => "drive_C@test_agent",
                "lastCheckTime" => "11 => 23",
                "result"        => 38.0,
                "status"        => "OK";

            },

            # ...
        ]
    }


=head1 SEE ALSO

L<Monitis> L<Monitis::Agents>

Official API page: L<http://monitis.com/api/api.html#addDriveMonitor>


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
