package Tapper::PRC;
# git description: v5.0.4-5-gf34ee88

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Program run control for test program automation
$Tapper::PRC::VERSION = '5.0.5';
use strict;
use warnings;

use IO::Socket::INET;
use YAML::Syck;
use Moose;
use Log::Log4perl;
use URI::Escape;

extends 'Tapper::Base';
with 'MooseX::Log::Log4perl';

has cfg => (is      => 'rw',
            isa     => 'HashRef',
            default => sub { {} },
           );
with 'Tapper::Remote::Net';


sub mcp_error
{

        my ($self, $error) = @_;
        $self->log->error($error);
        my $retval = $self->mcp_inform({status => 'error-testprogram', error => $error});
        $self->log->error($retval) if $retval;
        exit 1;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::PRC - Tapper - Program run control for test program automation

=head1 DESCRIPTION

This distribution implements a program run control for test program
automation. It is part of the Tapper distribution.

=head1 FUNCTIONS

=head2 mcp_error

Log an error and exit.

@param string - messages to send to MCP

@return never returns

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
