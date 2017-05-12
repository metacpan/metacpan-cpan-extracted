package Monitis::Memory;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add {
    my ($self, @params) = @_;

    my @mandatory = qw/agentkey tag name platform/;
    my @optional =
      qw/freeLimit freeSwapLimit freeVirtualLimit bufferedLimit cachedLimit/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addMemoryMonitor' => $params);
}

sub edit {
    my ($self, @params) = @_;

    my @mandatory = qw/testId tag name platform/;
    my @optional =
      qw/freeLimit freeSwapLimit freeVirtualLimit bufferedLimit cachedLimit /;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('editMemoryMonitor' => $params);
}

sub get {
    my ($self, @params) = @_;

    my @mandatory = qw/agentId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('agentMemory' => $params);
}

sub get_info {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('memoryInfo' => $params);
}

sub get_results {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId day month year/;
    my @optional  = qw/timezone/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('memoryResult' => $params);
}

sub get_top_results {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/timezoneoffset limit tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('topmemory' => $params);
}

__END__

=head1 NAME

Monitis::Memory - Predefined internal memory monitors manipulation

=head1 SYNOPSIS

    use Monitis::Memory;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::Memory> implements following attributes:

=head1 METHODS

L<Monitis::Memory> implements following methods:

=head2 add

    my $response = $api->memory->add(
        agentkey         => 'window_test_agent',
        tag              => 'test',
        name             => 'Monitor name',
        platform         => 'WINDOWS',
        freeVirtualLimit => 3000,
        freeLimit        => 2000,
        freeSwapLimit    => 1000,
    );

Create monitor.

Mandatory parameters:

    agentkey tag name platform

Mandatory parameters for LINUX, WINDOWS, OPENSOLARIS platforms:

    freeLimit freeSwapLimit

Mandatory parameters for WINDOWS platform:

    freeVirtualLimit

Mandatory parameters for LINUX platform:

    bufferedLimit cachedLimit

Normal response is:

    {   "data"   => {"testId" => 922},
        "status" => "ok"
    }

=head2 edit

    my $response = $api->memory->edit(
        testId           => 922,
        name             => 'new test',
        tag              => 'test',
        platform         => 'WINDOWS',
        freeVirtualLimit => 5000,
        freeLimit        => 3000,
        freeSwapLimit    => 2000,
    );

Edit monitor.

Mandatory parameters:

    testId tag name platform

Mandatory parameters for LINUX, WINDOWS, OPENSOLARIS platforms:

    freeLimit freeSwapLimit

Mandatory parameters for WINDOWS platform:

    freeVirtualLimit

Mandatory parameters for LINUX platform:

    bufferedLimit cachedLimit

Normal response is:

    {"status" => "ok"}

=head2 get

    my $response = $api->memory->get(agentId => 922);

Get monitor details.

Mandatory parameters:

    agentId

Response:

    See L<http://monitis.com/api/api.html#getMemoryMonitor>

=head2 get_info

    my $response = $api->memory->get_info(monitorId => 922);

Get monitor info.

Mandatory parameters:

    monitorId

Response:

    See L<http://monitis.com/api/api.html#getMemoryMonitorInfo>

=head2 get_results

    my $response = $api->memory->get_results(
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

    [   {   "time"         => "00 => 03",
            "freeMemory"   => 376.43,
            "totalMemory"  => 2029.84,
            "freeswap"     => 2261.57,
            "totalSwap"    => 3922.43,
            "freeVirtual"  => 1978.82,
            "totalVirtual" => 2047.88,
            "buffered"     => 512.21,
            "cached"       => 431.54,
            "status"       => "OK"
        },

        # ...
    ]

=head2 get_top_results

    my $response = $api->memory->get_top_results;

Get monitor top results.

Optional parameters:

    timezoneoffset limit tag

Normal response is:

    {   "tags" => [
            "Trans US-WST",    # ...
        ],
        "tests" => [
            {   "id"            => 1526,
                "testName"      => "memory@win_agent",
                "lastCheckTime" => "11 => 48",
                "result"        => 365.0,
                "status"        => "OK"
            },

            # ...
        ]
    }


=head1 SEE ALSO

L<Monitis> L<Monitis::Agents>

Official API page: L<http://monitis.com/api/api.html#addMemoryMonitor>


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
