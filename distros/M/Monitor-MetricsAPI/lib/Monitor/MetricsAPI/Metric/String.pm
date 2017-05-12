use strict;
use warnings;

package Monitor::MetricsAPI::Metric::String;
$Monitor::MetricsAPI::Metric::String::VERSION = '0.900';
use namespace::autoclean;
use Moose;

extends 'Monitor::MetricsAPI::Metric';

=head1 NAME

Monitor::MetricsAPI::Metric::String - String metric class for Monitor::MetricsAPI

=head1 SYNOPSIS

    use Monitor::MetricsAPI;

    my $collector = Monitor::MetricsAPI->new(
        metrics => { host => { name => 'string' } }
    );

    use Sys::Hostname;
    $collector->metric('host/name')->set(hostname());

=head1 DESCRIPTION

String metrics allow you to track any arbitrary string values in your metric
reporting output that you may wish to include. String metrics are initialized
as empty strings.

=cut

sub BUILD {
    my ($self) = @_;

    $self->_set_value('');
}

=head1 METHODS

String metrics do not provide any additional methods beyond the base methods
offered by L<Monitor::MetricsAPI::Metric>.

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

__PACKAGE__->meta->make_immutable;
1;
