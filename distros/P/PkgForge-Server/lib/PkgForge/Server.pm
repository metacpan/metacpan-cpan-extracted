package PkgForge::Server;    # -*-perl-*-
use strict;
use warnings;

# $Id: Server.pm.in 15407 2011-01-12 17:03:16Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15407 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Server.pm.in $
# $Date: 2011-01-12 17:03:16 +0000 (Wed, 12 Jan 2011) $

our $VERSION = '1.1.10';

1;
__END__

=head1 NAME

PkgForge::Server - PkgForge server classes

=head1 VERSION

This documentation refers to PkgForge::Server version 1.1.10

=head1 SYNOPSIS

   use PkgForge::Daemon::Incoming;

   my $daemon = PkgForge::Daemon::Incoming->new_with_options();

   $daemon->run();

=head1 DESCRIPTION

The Package Forge server suite (PkgForge::Server) provides all the
necessary infrastructure for running various services as either
one-shot scripts or as daemons. Currently there are two services, one
for processing the queue of newly submitted, incoming jobs and another
for actually building those jobs on particular platforms.

All the code related to the execution of the actual work done by a
service is written as a handler. See L<PkgForge::Handler> for details.

There are applications provided to run these services in a one-off
(i.e. process the queue once or build the first job in the queue. See
L<PkgForge::App> for details.

There are also classes to run these services as permanently running
daemons. See L<PkgForge::Daemon> for details.

=head1 DEPENDENCIES

You will need the L<PkgForge> and L<PkgForge::Registry> sets of Perl
modules installed and configured.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Daemon::Incoming>, L<PkgForge::Daemon::Buildd>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux5, Fedora13

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2010-2011 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut



