package Selenium::Remote::Mock::Commands;
$Selenium::Remote::Mock::Commands::VERSION = '1.49';
# ABSTRACT: utility class to mock Selenium::Remote::Commands

use strict;
use warnings;

use Moo;
extends 'Selenium::Remote::Commands';


# override get_params so we do not rewrite the parameters

sub get_params {
    my $self    = shift;
    my $args    = shift;
    my $data    = {};
    my $command = delete $args->{command};
    $data->{'url'}                = $self->get_url($command);
    $data->{'method'}             = $self->get_method($command);
    $data->{'no_content_success'} = $self->get_no_content_success($command);
    $data->{'url_params'}         = $args;
    return $data;
}

sub get_method_name_from_parameters {
    my $self        = shift;
    my $params      = shift;
    my $method_name = '';
    my $cmds        = $self->get_cmds();
    foreach my $cmd ( keys %{$cmds} ) {
        if (   ( $cmds->{$cmd}->{method} eq $params->{method} )
            && ( $cmds->{$cmd}->{url} eq $params->{url} ) )
        {
            $method_name = $cmd;
            last;
        }
    }
    return $method_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Remote::Mock::Commands - utility class to mock Selenium::Remote::Commands

=head1 VERSION

version 1.49

=head1 DESCRIPTION

Utility class to be for testing purposes, with L<Selenium::Remote::Mock::RemoteConnection> only.

=for Pod::Coverage *EVERYTHING*

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

Previous maintainers:

=over 4

=item *

Daniel Gempesaw <gempesaw@gmail.com>

=item *

Emmanuel Peroumalnaïk <peroumalnaik.emmanuel@gmail.com>

=item *

Luke Closs <cpan@5thplane.com>

=item *

Mark Stosberg <mark@stosberg.com>

=back

Original authors:

=over 4

=item *

Aditya Ivaturi <ivaturi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010-2011 Aditya Ivaturi, Gordon Child

Copyright (c) 2014-2017 Daniel Gempesaw

Copyright (c) 2018-2021 George S. Baugh

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
