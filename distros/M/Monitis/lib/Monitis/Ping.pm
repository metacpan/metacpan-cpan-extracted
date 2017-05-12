package Monitis::Ping;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add {
    my ($self, @params) = @_;

    my @mandatory =
      qw/userAgentId maxLost packetsCount packetsSize timeout url name tag/;
    my @optional = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addInternalPingMonitor' => $params);
}

sub edit {
    my ($self, @params) = @_;

    my @mandatory =
      qw/testId maxLost packetsCount packetsSize timeout name tag/;
    my @optional = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('editInternalPingMonitor' => $params);
}

sub get {
    my ($self, @params) = @_;

    my @mandatory = qw/agentId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('agentPingTests' => $params);
}

sub get_info {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('internalPingInfo' => $params);
}

sub get_results {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId day month year/;
    my @optional  = qw/timezone/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('internalPingResult' => $params);
}

__END__

=head1 NAME

Monitis::Ping - Predefined internal ping monitors manipulation

=head1 SYNOPSIS

    use Monitis::Ping;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::Ping> implements following attributes:

=head1 METHODS

L<Monitis::Ping> implements following methods:

=head2 add

    my $response = $api->ping->add(
        userAgentId  => 4568,
        maxLost      => 2,
        packetsCount => 5,
        packetsSize  => 32,
        timeout      => 1000,
        url          => 'google.com',
        name         => 'test agent',
        tag          => 'test'
    );

Create monitor.

Mandatory parameters:

    userAgentId maxLost packetsCount packetsSize timeout url name tag

Normal response is:

    {   "status" => "ok",
        "data"   => {"testId" => 1368}
    }

=head2 edit

    my $response = $api->ping->edit(
        testId  => 922,
        maxLost      => 1,
        packetsCount => 5,
        packetsSize  => 32,
        timeout      => 1000,
        url          => 'google.com',
        name         => 'test agent',
        tag          => 'test'
    );

Edit monitor.

Mandatory parameters:

    testId maxLost packetsCount packetsSize timeout name tag

Normal response is:

    {"status" => "ok"}

=head2 get

    my $response = $api->ping->get(agentId => 922);

Get monitor details.

Mandatory parameters:

    agentId

Response:

    [   {   "id"            => 68,
            "name"          => "test@google",
            "tag"           => "Default",
            "url"           => "google_windows",
            "timeout"       => 10000,
            "packetTimeout" => 1000,
            "packetCount"   => 7,
            "packetSize"    => 32,
            "maxLost"       => 4
        },

        # ...

    ]

=head2 get_info

    my $response = $api->ping->get_info(monitorId => 922);

Get monitor info.

Mandatory parameters:

    monitorId

Response:

    {   "id"            => 68,
        "name"          => "test@google",
        "tag"           => "Default",
        "url"           => "google_windows",
        "timeout"       => 10,
        "packetTimeout" => 1000,
        "packetCount"   => 4,
        "packetSize"    => 32,
        "maxLost"       => 4
    }

=head2 get_results

    my $response = $api->ping->get_results(
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

    See L<http://monitis.com/api/api.html#getPingMonitorResults>


=head1 SEE ALSO

L<Monitis> L<Monitis::Agents>

Official API page: L<http://monitis.com/api/api.html#addPingMonitor>


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
