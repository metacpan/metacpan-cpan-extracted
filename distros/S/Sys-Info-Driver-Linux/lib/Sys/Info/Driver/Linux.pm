package Sys::Info::Driver::Linux;
$Sys::Info::Driver::Linux::VERSION = '0.7905';
use strict;
use warnings;
use base qw( Exporter );

our @EXPORT = qw( proc );

use constant proc => { ## no critic (NamingConventions::Capitalization)
    loadavg  => '/proc/loadavg', # average cpu load
    cpuinfo  => '/proc/cpuinfo', # cpu information
    uptime   => '/proc/uptime',  # uptime file
    version  => '/proc/version', # os version
    meminfo  => '/proc/meminfo',
    swaps    => '/proc/swaps',
    fstab    => '/etc/fstab',    # for filesystem type of the current disk
    resolv   => '/etc/resolv.conf',
    timezone => '/etc/timezone',
    issue    => '/etc/issue',
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Info::Driver::Linux

=head1 VERSION

version 0.7905

=head1 SYNOPSIS

    use Sys::Info::Driver::Linux;

=head1 DESCRIPTION

This is the main module in the C<Linux> driver collection.

=head1 NAME

Sys::Info::Driver::Linux - Linux driver for Sys::Info

=head1 METHODS

None.

=head1 CONSTANTS

=head2 proc

Automatically exported. Includes paths to several files.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
