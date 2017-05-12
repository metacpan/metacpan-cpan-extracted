package Monitis::HTTP;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add {
    my ($self, @params) = @_;

    my @mandatory =
      qw/userAgentId contentMatchFlag contentMatchString httpMethod timeout url name tag passAuth userAuth /;
    my @optional = qw/loadFull overSSL postData redirect /;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addInternalHttpMonitor' => $params);
}

sub edit {
    my ($self, @params) = @_;

    my @mandatory =
      qw/testId contentMatchString httpMethod urlParams timeout name tag/;
    my @optional = qw/passAuth userAuth postData/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('editInternalHttpMonitor' => $params);
}

sub get {
    my ($self, @params) = @_;

    my @mandatory = qw/agentId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('agentHttpTests' => $params);
}

sub get_info {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('internalHttpInfo' => $params);
}

sub get_results {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId day month year/;
    my @optional  = qw/timezone/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('internalHttpResult' => $params);
}


__END__

=head1 NAME

Monitis::HTTP - Predefined internal HTTP monitors manipulation

=head1 SYNOPSIS

    use Monitis::HTTP;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::HTTP> implements following attributes:

=head1 METHODS

L<Monitis::HTTP> implements following methods:

=head2 add

    my $response = $api->http->add(
        userAgentId        => 4568,
        contentMatchFlag   => 1,
        contentMatchString => 'Google',
        httpMethod         => 'GET',
        timeout            => 1000,
        url                => 'http://google.com',
        name               => 'test agent',
        tag                => 'test'
    );

Create monitor.

Mandatory parameters:

    userAgentId contentMatchFlag contentMatchString httpMethod timeout url name tag

Mandatory parameters for httpMethod POST:

    postData

Mandatory parameters for overSSL:

    passAuth userAuth

Optional  parameters:

    loadFull overSSL redirect

Normal response is:

    {   "status" => "ok",
        "data"   => {
            "startDate" => "2010-10-18 18 => 14",
            "testId"    => 1368
        }
    }

=head2 edit

    my $response = $api->http->edit(
        testId             => 922,
        contentMatchString => 'Google',
        httpMethod         => 'GET',
        timeout            => 1000,
        url                => 'http://google.com',
        urlParams          => '',
        name               => 'test agent',
        tag                => 'test'
    );

Edit monitor.

Mandatory parameters:

    testId contentMatchString httpMethod urlParams timeout name tag

Mandatory parameters for httpMethod POST:

    postData

Mandatory parameters for overSSL:

    passAuth userAuth

Normal response is:

    {"status" => "ok"}

=head2 get

    my $response = $api->http->get(agentId => 922);

Get monitor details.

Mandatory parameters:

    agentId

Response:

    [   {   "id"           => 589,
            "name"         => "google_windows",
            "tag"          => "Default",
            "url"          => "google.com",
            "port"         => 80,
            "httpmethod"   => 0,
            "postData"     => "",
            "timeout"      => 10,
            "useSSL"       => "false",
            "userAuth"     => "",
            "passwordAuth" => "",
            "matchFlag"    => "true",
            "matchText"    => "",
            "doRedirect"   => "false",
            "loadFullPage" => "false"
        }

        # ...
    ]

=head2 get_info

    my $response = $api->http->get_info(monitorId => 922);

Get monitor info.

Mandatory parameters:

    monitorId

Response:

    See L<http://monitis.com/api/api.html#getHTTPMonitorInfo>

=head2 get_results

    my $response = $api->http->get_results(
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

    See L<http://monitis.com/api/api.html#getHTTPMonitorResults>


=head1 SEE ALSO

L<Monitis> L<Monitis::Agents>

Official API page: L<http://monitis.com/api/api.html#addHTTPMonitor>


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
