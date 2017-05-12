#! /usr/bin/perl
# PODNAME: tapper-installer-client
# ABSTRACT: cmdline frontend to Installer.simnow

use warnings;
use strict;
use Log::Log4perl;
use Daemon::Daemonize qw/:all/;

use Tapper::Installer::Base;

BEGIN {
        Log::Log4perl::init('/etc/log4perl.cfg');
}

# don't use the config of the last simnow session
system("rm","/etc/tapper") if -e "/etc/tapper";


Daemon::Daemonize->daemonize(close => "std");


my $client = new Tapper::Installer::Base;
$client->system_install("simnow");

__END__

=pod

=encoding UTF-8

=head1 NAME

tapper-installer-client - cmdline frontend to Installer.simnow

=head1 SYNOPSIS

tapper-installer-client.pl

=head1 DESCRIPTION

This program is the start script of the Tapper::Installer project. It calls
Tapper::Installer::Base which cares for the rest.

=head1 NAME

tapper-installer-client.pl - control the installation and setup of an automatic test system

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
