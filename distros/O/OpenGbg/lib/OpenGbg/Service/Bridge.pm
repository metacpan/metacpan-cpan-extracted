use 5.10.0;
use strict;
use warnings;

package OpenGbg::Service::Bridge;

# ABSTRACT: Entry point to the Bridge service
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1402';

use OpenGbg::Elk;
use namespace::autoclean;
use Types::Standard qw/Str/;

use OpenGbg::Service::Bridge::GetIsCurrentlyOpen;
use OpenGbg::Service::Bridge::GetOpenedStatus;

with 'OpenGbg::Service::Getter';

has handler => (
    is => 'ro',
    required => 1,
);
has service_base => (
    is => 'rw',
    isa => Str,
    default => 'BridgeService/v1.0/',
);

sub get_is_currently_open {
    my $self = shift;

    my $url = 'GetGABOpenedStatus/%s?';
    my $response = $self->getter($url, 'get_is_currently_open');

    return OpenGbg::Service::Bridge::GetIsCurrentlyOpen->new(xml => $response);
}
sub get_opened_status {
    my $self = shift;
    my $start = shift;
    my $end = shift;

    my $url = "GetGABOpenedStatus/%s/$start/$end?";
    my $response = $self->getter($url, 'get_opened_status');

    return OpenGbg::Service::Bridge::GetOpenedStatus->new(xml => $response);
}

sub is_open {
    return shift->get_is_currently_open->is_open;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

OpenGbg::Service::Bridge - Entry point to the Bridge service

=head1 VERSION

Version 0.1402, released 2016-08-12.

=head1 SYNOPSIS

    my $bridge = OpenGbg->new->bridge;
    my $response = $bridge->get_is_currently_open;

    print $response->is_open ? 'It is open' : 'It is closed';

=head1 DESCRIPTION

The Göta älvbron is a major bascule bridge in Gothenburg that opens more or less daily. This service publishes two methods with regards to its status.

L<Official documentation|http://data.goteborg.se/Pages/Webservice.aspx?ID=24>

See L<OpenGbg> for general information.

=head1 METHODS

=head2 get_is_currently_open

This method is for checking if the bridge is currently open.

Returns a L<GetIsCurrentlyOpen|OpenGbg::Service::Bridge::GetIsCurrentlyOpen> object.

=head2 get_opened_status($startdate, $enddate)

This method is for checking when it was opened in the past.

C<$startdate> and C<$enddate> are mandatory filtering arguments, both are expected to be in the iso-8601 representation: C<yyyy-mm-dd>. The ending date is not inclusive.

Returns a L<GetOpenedStatus|OpenGbg::Service::Bridge::GetOpenedStatus> object.

=head1 SOURCE

L<https://github.com/Csson/p5-OpenGbg>

=head1 HOMEPAGE

L<https://metacpan.org/release/OpenGbg>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
