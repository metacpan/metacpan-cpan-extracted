package Sys::Info::Driver::Linux;
use strict;
use warnings;
use vars qw( $VERSION @ISA @EXPORT );
use base qw( Exporter );

$VERSION = '0.7903';
@EXPORT  = qw( proc );

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

=head1 NAME

Sys::Info::Driver::Linux - Linux driver for Sys::Info

=head1 SYNOPSIS

    use Sys::Info::Driver::Linux;

=head1 DESCRIPTION

This document describes version C<0.7903> of C<Sys::Info::Driver::Linux>
released on C<8 May 2013>.

This is the main module in the C<Linux> driver collection.

=head1 METHODS

None.

=head1 CONSTANTS

=head2 proc

Automatically exported. Includes paths to several files.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2013 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
=cut
