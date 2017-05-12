#! /usr/bin/perl
# PODNAME: tapper_reports_web_fastcgi.pl
# ABSTRACT: Tapper - web gui start script - fastcgi

# Explicitely only for the live environment on bancroft

BEGIN {
        $ENV{CATALYST_ENGINE}          ||= 'FastCGI';
        $ENV{TAPPER_REPORTS_WEB_LIVE} ||= '1';
        $ENV{CATALYST_DEBUG}             = 0 unless defined $ENV{CATALYST_DEBUG};
}

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Tapper::Reports::Web;

my $help = 0;
my ( $listen, $nproc, $pidfile, $manager, $detach, $keep_stderr );

GetOptions(
    'help|?'      => \$help,
    'listen|l=s'  => \$listen,
    'nproc|n=i'   => \$nproc,
    'pidfile|p=s' => \$pidfile,
    'manager|M=s' => \$manager,
    'daemon|d'    => \$detach,
    'keeperr|e'   => \$keep_stderr,
);

pod2usage(1) if $help;

Tapper::Reports::Web->run(
    $listen,
    {   nproc   => $nproc,
        pidfile => $pidfile,
        manager => $manager,
        detach  => $detach,
        keep_stderr => $keep_stderr,
    }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

tapper_reports_web_fastcgi.pl - Tapper - web gui start script - fastcgi

=head1 SYNOPSIS

tapper_reports_web_fastcgi_live.pl [options]

 Options:
   -? -help      display this help and exits
   -l -listen    Socket path to listen on
                 (defaults to standard input)
                 can be HOST:PORT, :PORT or a
                 filesystem path
   -n -nproc     specify number of processes to keep
                 to serve requests (defaults to 1,
                 requires -listen)
   -p -pidfile   specify filename for pid file
                 (requires -listen)
   -d -daemon    daemonize (requires -listen)
   -M -manager   specify alternate process manager
                 (FCGI::ProcManager sub-class)
                 or empty string to disable
   -e -keeperr   send error messages to STDOUT, not
                 to the webserver

=head1 DESCRIPTION

Run a Tapper Reports Web application as fastcgi.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
