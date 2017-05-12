package Tapper::Remote;
# git description: v4.1.1-3-gd09d5f0

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Common functionality for remote automation libs
$Tapper::Remote::VERSION = '5.0.0';
use warnings;
use strict;
use Moose;

extends 'Tapper::Base';
has cfg =>  (is => 'rw', isa => 'HashRef', default => sub { {} });


sub BUILD
{
        my ($self, $config) = @_;
        $self->{cfg}=$config;
}


1; # End of Tapper::Remote

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Remote - Tapper - Common functionality for remote automation libs

=head1 SYNOPSIS

This module contains functions that are equal for all remote Tapper
projects (currently Tapper::PRC and Tapper::Installer).
Tapper::Remote itself does not export functionality but instead is the
base image for all modules of the project.

=head2 BUILD

Initialize config.

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
