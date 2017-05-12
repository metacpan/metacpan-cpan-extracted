package Monitis::VisitorTrackers;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub get {
    my $self = shift;

    return $self->api_get('visitorTrackingTests');
}

sub get_info {
    my ($self, @params) = @_;

    my @mandatory = qw/siteId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('visitorTrackingInfo' => $params);
}

sub get_results {
    my ($self, @params) = @_;

    my @mandatory = qw/siteId year month day/;
    my @optional  = qw/timezoneoffset/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('visitorTrackingResults' => $params);
}

__END__

=head1 NAME

Monitis::VisitorTrackers - Visitors tracking info

=head1 SYNOPSIS

    use Monitis::VisitorTrackers;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::VisitorTrackers> implements following attributes:

=head1 METHODS

L<Monitis::VisitorTrackers> implements following methods:

=head2 get

    my $response = api->visitor_trackers->get;

Get visitor trackers.

Normal response is:

    [   [40, "mon.itor.us", "mon", "1040"],

        # ...
    ]

=head2 get_info

    $response = api->visitor_trackers->get_info(siteId => $site_id);

Get visitor tracker info.

Mandatory parameters:

    siteId - id of the visitor tracker.

Normal response is:

    {   "id"         => 80,
        "createdOn"  => "2007-07-14 09 => 33 => 28.0",
        "activeFlag" => 1,
        "tag"        => "Default",
        "name"       => "mon",
        "sId"        => "1040",
        "url"        => "mon.itor.us"
    }

=head2 get_results

    $response = api->visitor_trackers->get_results(
        siteId => $site_id,
        day    => '29',
        month  => '5',
        year   => '2011'
    );

Get visitor tracker results.

Mandatory parameters:

    siteId - id of the visitor tracker;
    year - year that results should be retrieved for;
    month - month that results should be retrieved for;
    day - day that results should be retrieved for.

Optional parameters:

    timezoneoffset - offset relative to GMT, used to show results in the timezone of the user.

Normal response is:

    {   "trend" => {
            "totalVisits" => 218,
            "totalViews"  => 324
        },
        "data" => [
            ["01 => 00", 12, 7],

            # ...
        ]
    }


=head1 SEE ALSO

L<Monitis>

Official API page: L<http://monitis.com/api/api.html#getVisitorTrackers>


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

