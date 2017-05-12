use strict;
use warnings;

package Monitor::MetricsAPI::Server;
$Monitor::MetricsAPI::Server::VERSION = '0.900';
use Plack::Builder;
use Twiggy::Server;

use Monitor::MetricsAPI::Server::Routes;

=head1 NAME

Monitor::MetricsAPI::Server - Metrics eporting server for Monitor::MetricsAPI

=head1 SYNOPSIS

You should not interact with this module directly in your code. Please refer to
L<Monitor::MetricsAPI> for how to integrate this service with your application.

=head1 DESCRIPTION

=cut

=head1 METHODS

=head2 new ($address, $port)

Constructs and returns a Twiggy::Server object with a single Dancer2 service
registered at / which will handle all incoming HTTP API requests. Both $address
and $port are optional, and will default to '0.0.0.0' and 8200, respectively.

=cut

sub new {
    my ($class, $address, $port) = @_;

    $address //= '0.0.0.0';
    $port    //= 8200;

    my $server = Twiggy::Server->new(
        host => $address,
        port => $port,
    );
    $server->register_service(builder {
        mount '/' => Monitor::MetricsAPI::Server::Routes->to_app;
    });

    return $server;
}

=head1 AUTHORS

Jon Sime <jonsime@gmail.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2015 by OmniTI Computer Consulting, Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
