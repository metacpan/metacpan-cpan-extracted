package Tapper::MCP;
# git description: v5.0.5-1-g0edf36d

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Central master control program of Tapper automation
$Tapper::MCP::VERSION = '5.0.6';
use warnings;
use strict;

use Tapper::Config;
use Moose;

extends 'Tapper::Base';

sub cfg
{
        my ($self) = @_;
        return Tapper::Config->subconfig();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP - Tapper - Central master control program of Tapper automation

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
