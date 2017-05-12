package Monitis::ExternalMonitors;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add {
    my ($self, @params) = @_;

    my @mandatory = qw/type name url interval timeout locationIds tag/;

# TODO: right checks for detailedTestType postData contentMatchFlag contentMatchString
    my @optional =
      qw/detailedTestType overSSL postData contentMatchFlag contentMatchString params/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addExternalMonitor' => $params);
}

sub edit {
    my ($self, @params) = @_;

    my @mandatory = qw/testId name url locationIds timeout tag/;
    my @optional  = qw/contentMatchString maxValue/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('editExternalMonitor' => $params);
}

sub delete {
    my ($self, @params) = @_;

    my @mandatory = qw/testIds/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('deleteExternalMonitor' => $params);
}

sub suspend {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/monitorIds tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('suspendExternalMonitor' => $params);
}

sub activate {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/monitorIds tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('activateExternalMonitor' => $params);
}

sub get_locations {
    my $self = shift;

    return $self->api_get('locations');
}

sub get_monitors {
    my $self = shift;

    return $self->api_get('tests');
}

sub get_monitor_info {
    my ($self, @params) = @_;

    my @mandatory = qw/testId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('testinfo' => $params);
}

sub get_monitor_results {
    my ($self, @params) = @_;

    my @mandatory = qw/testId day month year/;
    my @optional  = qw/locationIds timezone/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('testresult' => $params);
}

sub get_snapshot {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/locationIds/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('testsLastValues' => $params);
}

sub get_top_results {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/timezoneoffset limit tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('topexternal' => $params);
}

sub get_tags {
    my $self = shift;

    return $self->api_get('tags');
}

sub get_by_tag {
    my ($self, @params) = @_;

    my @mandatory = qw/tag/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('tagtests' => $params);
}


__END__

=head1 NAME

Monitis::ExternalMonitors - External monitors manipulation

=head1 SYNOPSIS

    use Monitis::ExternalMonitors;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::ExternalMonitors> implements following attributes:

=head1 METHODS

L<Monitis::ExternalMonitors> implements following methods:

=head2 add

    my $response = $api->external_monitors->add(
        type        => 'http',
        name        => 'New Test',
        url         => 'http://google.com',
        interval    => 10,
        timeout     => 10000,
        locationIds => '1,11',
        tag         => 'new tag'
    );

Add new external monitor.

Mandatory parameters:

    type name url interval timeout locationIds tag

Optional parameters:

    detailedTestType overSSL postData contentMatchFlag contentMatchString params

Normal response is:

    {   "status" => "ok",
        "data"   => {
            "startDate" => "2010-10-18 15 => 18",
            "testId"    => 36958,
            "isTestNew" => "1"
        }
    }

=head2 edit

    my $response = $api->external_monitors->edit(
        testId  => 36958,
        name    => 'Old test',
        timeout => 4000
    );

Add new external monitor.

Mandatory parameters:

    testId name url locationIds timeout tag

Optional parameters:

    contentMatchString maxValue

Normal response is:

    {   "status" => "ok",
        "data"   => {
            "startDate" => "2010-10-18 15 => 18",
            "testId"    => 36958,
            "isTestNew" => "1"
        }
    }

=head2 delete

    my $response = $api->external_monitors->delete(
        testIds  => '36958,36959'
    );

Delete external monitors.

Mandatory parameters:

    testIds

Normal response is:

    {"status" => "ok"}

=head2 suspend

    my $response = $api->external_monitors->suspend(
        testIds  => '36958,36959'
    );

Suspend external monitors.

Mandatory parameters:

    testIds or tag

Normal response is:

    {   "status" => "ok",
        "data"   => {"failedToSuspend" => [10405, 86758, 35748]}
    }

=head2 activate

    my $response = $api->external_monitors->activate(
        testIds  => '36958,36959'
    );

Activate external monitors.

Mandatory parameters:

    testIds or tag

Normal response is:

    {"status" => "ok"}

=head2 get_locations

    my $response = $api->external_monitors->get_locations;

Get locations list.

Normal response is:

    [   {   "id"               => 5,
            "name"             => "US-MID",
            "minCheckInterval" => 1
        },

        # ...
    ]

=head2 get_monitors

    my $response = $api->external_monitors->get_monitors;

Get monitors list.

Normal response is:

    {   "testList" => [
            {   "id"          => 2755,
                "name"        => "yahoo_http_444",
                "isSuspended" => 0,
                "type"        => "http"
            },

            # ...
        ]
    }

=head2 get_monitor_info

    my $response = $api->external_monitors->get_monitor_info(testId => 2755);

Get monitor info.

Mandatory parameters:

    testId

Normal response is:

    {   "startDate" => "2010-03-10 08 => 42",
        "timeout"   => 5,
        "type"      => "dns",
        "postData"  => null,
        "testId"    => 25871,
        "match"     => null,
        "matchText" => null,
        "params"    => {
            "3"    => "aa",
            "bbb"  => "cccc",
            "dddd" => "eeee"
        },
        "tag"          => "tag1",
        "detailedType" => null,
        "url"          => "google.com",
        "name"         => "google_dns",
        "locations"    => [
            {   "checkInterval" => 5,
                "fullName"      => "Australia",
                "name"          => "AU",
                "id"            => 6
            },

            # ...
        ]
    }

=head2 get_monitor_results

    my $response = $api->external_monitors->get_monitor_results(
        testId => 2755,
        day    => 12,
        month  => 5,
        yea    => 2011
    );

Get monitor info.

Mandatory parameters:

    testId day month year

Optional parameters:

    locationIds timezone

Normal response is:

    [   {   "id"           => 7,
            "locationName" => "DE",
            "trend"        => {
                "min"      => 65.0,
                "okcount"  => 1440,
                "max"      => 3154.0,
                "oksum"    => 110721.0,
                "nokcount" => 1
            },
            "data" => [
                ["2010-03-16 00 => 00", 115.0, "OK"],
                ["2010-03-16 00 => 01", 117.0, "OK"],

                # ...
                ["2010-03-16 23 => 58", 0.0,   "NOK"],
                ["2010-03-16 23 => 59", 146.0, "OK"]
            ],
            "adddatas" => [["Connection lasted more than 10 seconds.", 1]]
        }

        # ...
    ]

=head2 get_snapshot

    my $response = $api->external_monitors->get_snapshot;

Get latest test values.

Optional parameters:

    locationIds

Normal response is:

    [   {   "locationName" => "US-MID",
            "id"           => 6,
            "data"         => [
                {   "time"    => "9 Mar 2010 14 => 58 => 33 GMT",
                    "tag"     => "aaaa",
                    "perf"    => 736.0,
                    "status"  => "OK",
                    "name"    => "yahoo.com_http",
                    "id"      => 15613,
                    "timeout" => 10000
                },

                # ...
            ]
        },

        # ...
    ]

=head2 get_top_results

    my $response = $api->external_monitors->get_top_results;

Get test top results.

Optional parameters:

    timezoneoffset limit tag

Normal response is:

    {   "tags" => [
            "Default", "EC2",

            # ...
        ],
        "tests" => [
            {   "id"            => 5481,
                "testName"      => "google.com_http",
                "lastCheckTime" => "13 => 05",
                "result"        => 603.0,
                "status"        => "OK"
            },

            # ...
        ]
    }

=head2 get_tags

    my $response = $api->external_monitors->get_tags;

Get monitor tag list.

Normal response is:

    {   "tags" => [
            {   "rank"  => 12,
                "title" => "EC2"
            },

            # ...
        ]
    }

=head2 get_by_tag

    my $response = $api->external_monitors->get_by_tag(tag => 'my tag');

Get tests by tag.

Mandaytory parameters:

    tag

Normal response is:

    {   "testList" => [
            {   "id"   => 38965,
                "name" => "c2-99-168-239-273.compute-1.amazonaws.com_ssh"
            },

            # ...
        ]
    }


=head1 SEE ALSO

L<Monitis>

Official API page: L<http://monitis.com/api/api.html#addExternalMonitor>


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
