
package Monitis::TransactionMonitors;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub suspend {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/monitorIds tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('suspendTransactionMonitor' => $params);
}

sub activate {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/monitorIds tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('activateTransactionMonitor' => $params);
}

sub get {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/type/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('transactionTests' => $params);
}

sub get_monitor_info {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('transactionTestInfo' => $params);
}

sub get_monitor_result {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId year month day/;
    my @optional  = qw/locationIds timezone/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('transactionTestResult' => $params);
}

sub get_step_result {
    my ($self, @params) = @_;

    my @mandatory = qw/resultId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('transactionStepResult' => $params);
}

sub get_step_capture {
    my ($self, @params) = @_;

    my @mandatory = qw/monitorId resultId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    # TODO: Handling PNG should be tested!
    my $request =
      $self->build_get_request('transactionStepCapture' => $params);

    my $response = $self->ua->request($request);

    return $response->decoded_content;
}

sub get_step_net {
    my ($self, @params) = @_;

    my @mandatory = qw/resultId year month day/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('transactionStepNet' => $params);
}

__END__

=head1 NAME

Monitis::TransactionMonitors - Transaction monitors manipulation

=head1 SYNOPSIS

    use Monitis::TransactionMonitors;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::TransactionMonitors> implements following attributes:

=head1 METHODS

L<Monitis::TransactionMonitors> implements following methods:

=head2 suspend

    my $response = $api->transaction_monitors->suspend(monitorIds => '628,629');

Suspend monitors.

Mandatory parameters:

    monitorIds or tag

Normal response is:

    {   "status" => "ok",
        "data"   => {"failedToSuspend" => [628]}
    }

=head2 activate

    my $response =
      $api->transaction_monitors->activate(monitorIds => '628,629');

Activate monitors.

Mandatory parameters:

    monitorIds or tag

Normal response is:

    {"status" => "ok"}

=head2 get

    my $response =
      $api->transaction_monitors->get;

Get monitors.

Optional parameters:

    type

Normal response is:

    [   {   "id"        => 1835,
            "name"      => "Test",
            "tag"       => "test",
            "url"       => "monitis.com",
            "stepCount" => 2
        },

        # ...
    ]

=head2 get_monitor_info

    my $response = $api->transation_monitors->get_monitor_info(monitorId => 922);

Get monitor info.

Mandatory parameters:

    monitorId

Response:

    See L<http://monitis.com/api/api.html#getTransactionMonitorInfo>

=head2 get_monitor_result

    my $response = $api->transation_monitors->get_monitor_result(
        monitorId => 922,
        day       => 1,
        month     => 5,
        year      => 2011
    );

Get monitor result.

Mandatory parameters:

    agentId day month year

Optional parameters:

    timezone locationIds

Normal response is:

    See L<http://monitis.com/api/api.html#getTransactionMonitorResults>

=head2 get_step_result

    my $response =
      $api->transation_monitors->get_step_result(resultId => 922);

Get step result.

Mandatory parameters:

    resultId

Response:

    See L<http://monitis.com/api/api.html#getTransactionStepResults>

=head2 get_step_capture

    my $response = $api->transation_monitors->get_step_capture(
        resultId  => 922,
        monitorId => 1234
    );

Mandatory parameters:

    monitorId resultId

Response:

    PNG image

=head2 get_step_net

    my $response = $api->transation_monitors->get_step_net(
        resultId  => 922,
        monitorId => 1234
    );

Mandatory parameters:

    resultId year month day

Response:

    See L<http://monitis.com/api/api.html#getTransactionStepNet>


=head1 SEE ALSO

L<Monitis>

Official API page: L<http://monitis.com/api/api.html#getTransactionMonitors>


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

