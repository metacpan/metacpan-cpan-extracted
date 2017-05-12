package Tapper::MCP::Daemon;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Daemon::VERSION = '5.0.6';
use 5.010;

use strict;
use warnings;

use Tapper::MCP::Master;
use Moose;
use Tapper::Config;
use Log::Log4perl;

with 'MooseX::Daemonize';


after start => sub {
                    my $self = shift;

                    return unless $self->is_daemon;

                    my $daemon = Tapper::MCP::Master->new()->run;
                   };


sub run
{
        my $self = shift;

        my ($command) = @ARGV ? @ARGV : @_;
        return unless $command && grep /^$command$/, qw(start status stop);
        $self->$command;
        say $self->status_message;
}
;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Daemon

=head2 run

Frontend to subcommands: start, status, restart, stop.

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
