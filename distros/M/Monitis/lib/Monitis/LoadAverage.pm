package Monitis::LoadAverage;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add {
    my ($self, @params) = @_;

    my @mandatory = qw/agentkey limit1 limit5 limit15 name tag/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addLoadAverageMonitor' => $params);
}

sub edit {
    my ($self, @params) = @_;

    my @mandatory = qw/testId limit1 limit5 limit15 name tag/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('editLoadAverageMonitor' => $params);
}

sub get {
    my ($self, @params) = @_;

    my @mandatory = qw/agentId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('agentLoadAvg' => $params);
}

sub get_info {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('loadAvgInfo' => $params);
}

sub get_results {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId day month year/;
    my @optional  = qw/timezone/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('loadAvgResult' => $params);
}

sub topload1  { shift->get_top_results('topload1',  @_) }
sub topload5  { shift->get_top_results('topload5',  @_) }
sub topload10 { shift->get_top_results('topload10', @_) }

sub get_top_results {
    my ($self, $topload, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/timezoneoffset limit tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get($topload => $params);
}

__END__

=head1 NAME

Monitis::LoadAverage - Predefined internal load average monitors manipulation

=head1 SYNOPSIS

    use Monitis::LoadAverage;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::LoadAverage> implements following attributes:

=head1 METHODS

L<Monitis::LoadAverage> implements following methods:

=head2 add

    my $response = $api->load_average->add(
        agentkey => 'test_agent',
        limit1   => 8.2,
        limit5   => 9.3,
        limit15  => 9.5,
        name     => 'test from api',
        tag      => 'test'
    );

Create monitor.

Mandatory parameters:

    agentkey limit1 limit5 limit15 name tag

Normal response is:

    {   "data"   => {"testId" => 922},
        "status" => "ok"
    }

=head2 edit

    my $response = $api->load_average->edit(
        testId  => 922,
        limit1  => 4.2,
        limit5  => 5.3,
        limit15 => 7.5,
        name    => 'test from api',
        tag     => 'test'
    );

Edit monitor.

Mandatory parameters:

    testId limit1 limit5 limit15 name tag

Normal response is:

    {"status" => "ok"}

=head2 get

    my $response = $api->load_average->get(agentId => 922);

Get monitor details.

Mandatory parameters:

    agentId

Response:

    {   "id"         => 1588,
        "name"       => "load_test",
        "tag"        => "Default",
        "ip"         => "126.158.210.31",
        "maxLimit1"  => 5.0,
        "maxLimit5"  => 5.0,
        "maxLimit15" => 5.0
    }

=head2 get_info

    my $response = $api->load_average->get_info(monitorId => 922);

Get monitor info.

Mandatory parameters:

    monitorId

Response:

    See L<http://monitis.com/api/api.html#getDriveMonitorInfo>

=head2 get_results

    my $response = $api->load_average->get_result(
        monitorId => 922,
        day       => 1,
        month     => 5,
        year      => 2011
    );

Get monitor result.

Mandatory parameters:

    monitorId day month year

Optional parameters:

    timezone

Normal response is:

    [   {   "time"     => "00 => 10",
            "result1"  => 5.0,
            "result5"  => 8.3,
            "result15" => 10.1,
            "status"   => "OK"
        },

        # ...

    ]

=head2 topload1, topload5, topload10

Aliases for L<get_top_results>

=head2 get_top_results

    my $response = $api->load_average->get_top_results('topload1');

Get monitor top results.

Optional parameters:

    timezoneoffset limit tag

Normal response is:

    {   "tags" => [
            "Default",    # ...
        ],
        "tests" => [
            {   "id"            => 1258,
                "testName"      => "load_test",
                "lastCheckTime" => "12 => 00",
                "result"        => 10.0,
                "status"        => "OK"
            },

            # ...
        ]
    }


=head1 SEE ALSO

L<Monitis> L<Monitis::Agents>

Official API page: L<http://monitis.com/api/api.html#addLoadAvgMonitor>


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
