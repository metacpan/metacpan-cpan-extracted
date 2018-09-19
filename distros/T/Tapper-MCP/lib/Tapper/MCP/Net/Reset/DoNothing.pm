package Tapper::MCP::Net::Reset::DoNothing;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Net::Reset::DoNothing::VERSION = '5.0.7';
use strict;
use warnings;

use Moose;
extends 'Tapper::Base';


sub reset_host
{
        my ($self, $host, $options) = @_;

        $self->log->info("Just a fake-reboot, not real.");
        my ($error, $retval) = (1, "$host"."-".$options->{some_dummy_return_message});
        return ($error, $retval);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Net::Reset::DoNothing

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
