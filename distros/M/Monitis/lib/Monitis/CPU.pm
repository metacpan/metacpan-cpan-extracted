package Monitis::CPU;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add {
    my ($self, @params) = @_;

    my @mandatory = qw/agentkey kernelMax usedMax name tag/;
    my @optional  = qw/idleMin ioWaitMax niceMax/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addCPUMonitor' => $params);
}

sub edit {
    my ($self, @params) = @_;

    my @mandatory = qw/testId kernelMax usedMax name tag/;
    my @optional  = qw/idleMin ioWaitMax niceMax/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('editCPUMonitor' => $params);
}

sub get {
    my ($self, @params) = @_;

    my @mandatory = qw/agentId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('agentCPU' => $params);
}

sub get_info {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('CPUInfo' => $params);
}

sub get_results {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId day month year/;
    my @optional  = qw/timezone/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('cpuResult' => $params);
}

sub get_top_results {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/timezoneoffset limit tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('topcpu' => $params);
}

__END__

=head1 NAME

Monitis::CPU - Predefined internal CPU monitors manipulation

=head1 SYNOPSIS

    use Monitis::CPU;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::CPU> implements following attributes:

=head1 METHODS

L<Monitis::CPU> implements following methods:

=head2 add

    my $response = $api->cpu->add(
        agentkey  => 'test_linux_agent',
        idleMin   => 0,
        ioWaitMax => 100,
        kernelMax => 100,
        usedMax   => 100,
        name      => 'test_cpu_monitor',
        tag       => 'test'
    );

Create monitor.

Mandatory parameters:

    agentkey kernelMax usedMax name tag

Mandatory parameters for Linux agents also mandatory:

    idleMin ioWaitMax niceMax

Normal response is:

    {   "data"   => {"testId" => 922},
        "status" => "ok"
    }

=head2 edit

    my $response = $api->cpu->edit(
        testId    => 922,
        kernelMax => 100,
        usedMax   => 90,
        name      => 'new test',
        tag       => 'test'
    );

Edit monitor.

Mandatory parameters:

    testId kernelMax usedMax name tag

Mandatory parameters for Linux agents also mandatory:

    idleMin ioWaitMax niceMax

Normal response is:

    {   "data"   => {"testId" => 922},
        "status" => "ok"
    }

=head2 get

    my $response = $api->cpu->get(agentId => 922);

Get monitor details.

Mandatory parameters:

    agentId

Normal response is:

    {   "iowaitMax" => 100.0,
        "kernelMax" => 100.0,
        "userMax"   => 100.0,
        "idleMin"   => 0.0,
        "tag"       => "Default",
        "niceMax"   => 100.0,
        "name"      => "cpu@test_agent",
        "id"        => 7195,
        "ip"        => "218.156.215.118"
    }

=head2 get_info

    my $response = $api->cpu->get_info(monitorId => 922);

Get monitor info.

Mandatory parameters:

    monitorId

Normal response is:

    {   "iowaitMax"     => null,
        "kernelMax"     => 100.0,
        "agentPlatform" => "WINDOWS",
        "userMax"       => 100.0,
        "agentKey"      => "test_agent",
        "idleMin"       => null,
        "tag"           => "Default",
        "niceMax"       => null,
        "name"          => "cpuTest",
        "id"            => 1866,
        "ip"            => "218.156.213.15"
    }

=head2 get_results

    my $response = $api->cpu->get_results(
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

    [

        {   "time"        => "14 => 11",
            "userValue"   => 22.0,
            "kernelValue" => -1.0,
            "niceValue"   => 90.0,
            "idleValue"   => 112.0,
            "ioWaitValue" => 134.0,
            "status"      => "OK",
            "cpuIndex"    => 0
        }

        # . . .
    ]

=head2 get_top_results

    my $response = $api->cpu->get_top_results;

Get monitor top results.

Optional parameters:

    timezoneoffset limit tag

Normal response is:

    {   "tags" => [
            "Default",    # ...
        ],
        "tests" => [
            {   "id"            => 1526,
                "testName"      => "cpu@test_agent",
                "lastCheckTime" => "09 => 34",
                "result"        => 14.0,
                "status"        => "OK"
            },

            # ...
        ]
    }


=head1 SEE ALSO

L<Monitis> L<Monitis::Agents>

Official API page: L<http://monitis.com/api/api.html#addCPUMonitor>


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
