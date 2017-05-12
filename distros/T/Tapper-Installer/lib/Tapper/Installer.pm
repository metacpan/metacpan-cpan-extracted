package Tapper::Installer;
# git description: v4.1.1-6-g129f830

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Install everything needed for a test
$Tapper::Installer::VERSION = '5.0.0';
use strict;
use warnings;

use Moose;
use Socket;
use URI::Escape "uri_escape";

extends 'Tapper::Base';
with 'MooseX::Log::Log4perl';

has cfg => (is      => 'rw',
            default => sub { {} },
           );
with 'Tapper::Remote::Net';


sub BUILD
{
        my ($self, $config) = @_;
        $self->{cfg}=$config;
}


sub logdie
{
        my ($self, $msg) = @_;
        if ($self->cfg->{mcp_host}) {
                $self->mcp_send({state => 'error-install', error => $msg});
        } else {
                $self->log->error("Can't inform MCP, no server is set");
        }
        die $msg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Installer - Tapper - Install everything needed for a test

=head2 BUILD

Initialize with config.

=head1 FUNCTIONS

=head2 logdie

Tell the MCP server our current status, then die().

@param string - message to send to MCP

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
