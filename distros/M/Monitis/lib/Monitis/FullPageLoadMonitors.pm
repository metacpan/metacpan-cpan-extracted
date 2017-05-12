package Monitis::FullPageLoadMonitors;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add {
    my ($self, @params) = @_;

    my @mandatory = qw/name tag locationIds checkInterval url timeout/;
    my @optional  = qw/uptimeSLA responseSLA/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addFullPageLoadMonitor' => $params);
}

sub edit {
    my ($self, @params) = @_;

    my @mandatory =
      qw/monitorId name tag locationIds checkInterval url timeout/;
    my @optional = qw/uptimeSLA responseSLA /;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addFullPageLoadMonitor' => $params);
}

sub suspend {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/monitorIds tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('suspendFullPageLoadMonitor' => $params);
}

sub activate {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/monitorIds tag/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('activateFullPageLoadMonitor' => $params);
}

sub delete {
    my ($self, @params) = @_;

    my @mandatory = qw//;
    my @optional  = qw/monitorIds/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('deleteFullPageLoadMonitor' => $params);
}

__END__

=head1 NAME

Monitis::FullPageLoadMonitors - Full page load monitors manipulation

=head1 SYNOPSIS

    use Monitis::FullPageLoadMonitors;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::FullPageLoadMonitors> implements following attributes:

=head1 METHODS

L<Monitis::FullPageLoadMonitors> implements following methods:

=head2 add

    my $response = $api->full_page_load_monitors->add(
        name          => 4234234,
        tag           => 'test',
        locationIds   => '1,5',
        checkInterval => 3,
        url           => 'ya.ru',
        timeout       => 10
    );

Add full page load monitor.

Mandatory parameters:

    name - name of the monitor;
    tag - tag of the monitor;
    locationIds - comma separated ids of the locations to add monitor for;
    checkInterval - check interval in minutes;
    url - URL of the page to monitor;
    timeout - test timeout in ms.

Optional parameters:

    uptimeSLA - min allowed uptime(%);
    responseSLA - max allowed response time in seconds.

Normal response is:

    {   "status" => "ok",
        "data"   => {"testId" => 3028}
    }

=head2 edit

    my $response = $api->full_page_load_monitors->edit(
        monitorId     => $test_id,
        name          => '2342342',
        tag           => 'test',
        locationIds   => '1,5',
        checkInterval => '10',
        url           => 'foxcool.ru',
        timeout       => '5'
    );

Edit full page load monitor.

Mandatory parameters:

    monitorId - id of the monitor to edit;
    name - name of the monitor;
    tag - tag of the monitor;
    locationIds - comma separated ids of the locations to add monitor for;
    checkInterval - check interval in minutes;
    url - URL of the page to monitor;
    timeout - test timeout in ms.

Optional parameters:

    uptimeSLA - min allowed uptime(%);
    responseSLA - max allowed response time in seconds.

Normal response is:

    {   "status" => "ok",
        "data"   => {"testId" => 3028}
    }

=head2 suspend

    my $response = $api->full_page_load_monitors->suspend( tag => 'test' );

Suspend full page load monitors.

Mandatory parameters:

    monitorIds or tag.

Normal response is:

    {   "status" => "ok",
        "data"   => {"failedToSuspend" => [3495, 45768]}
    }

=head2 activate

    $api->full_page_load_monitors->activate( tag => 'test' );

Activate full page load monitors.

Mandatory parameters:

    monitorIds or tag.

Normal response is:

    {"status" => "ok"}

=head2 delete

    $api->full_page_load_monitors->delete( monitorIds => 1234 );

Delete monitors.

Mandatory parameters:

    monitorIds

Normal response is:

    {"status" => "ok"}


=head1 SEE ALSO

L<Monitis>

Official API page: L<http://monitis.com/api/api.html#addFullPageLoadMonitor>

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

