package Tapper::MCP::Net::Reset::Exec;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Net::Reset::Exec::VERSION = '5.0.7';
use strict;
use warnings;

use Moose;
extends 'Tapper::Base';


sub reset_host
{
        my ($self, $host, $options) = @_;

        $self->log->info("Try reboot via Exec");
        my $cmd = $options->{command}." $host";
        $self->log->info("trying $cmd");
        my ($error, $retval) = $self->log_and_exec($cmd);
        return ($error, $retval);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Net::Reset::Exec

=head1 DESCRIPTION

This is a plugin for Tapper.

It provides resetting a machine via the OSRC reset script (an internal
tool).

=head1 NAME

Tapper::MCP::Net::Reset::Exec - Reset by calling an executable

=head1

To use it add the following config to your Tapper config file:

 reset_plugin: OSRC
 reset_plugin_options:

This configures Tapper MCP to use the OSRC plugin for reset and
leaves configuration empty.

=head1 FUNCTIONS

=head2 reset_host ($self, $host, $options)

The primary plugin function.

It is called with the Tapper::MCP::Net object (for Tapper logging),
the hostname to reset and the options from the config file.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
