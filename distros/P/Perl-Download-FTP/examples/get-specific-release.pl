#!/usr/bin/env perl
use 5.12.0;
use warnings;
use Carp;
use Perl::Download::FTP;
use Getopt::Long;

=head1 NAME

get-specific-release.pl - Download a specific Perl release tarball

=head1 USAGE

    # ftp://ftp.funet.fi/pub/languages/perl/CPAN/src/5.0

    get-specific-release.pl \
        --host=ftp.funet.fi \
        --hostdir=/pub/languages/perl/CPAN/src/5.0 \
        --release=perl-5.27.1.tar.gz \
        --localpath=/home/jkeenan/var/bbc \
        --verbose

=cut

my ($host, $hostdir, $release, $verbose, $localpath);
GetOptions(
    # Values assigned to these 5 options will be checked by
    # Perl::Download::FTP methods
    "host=s"            => \$host,
    "hostdir=s"         => \$hostdir,
    # Does not need checking
    "verbose"           => \$verbose,
    # Need checking
    "localpath=s"       => \$localpath,
    "release=s"         => \$release,
) or croak "Unable to get command-line options";

my $msg = "Must specify local directory where tarball will be placed;";
$msg .= "  $localpath not found";
croak $msg unless ($localpath and (-d $localpath));

my $ftpobj = Perl::Download::FTP->new( {
    host        => $host,
    dir         => $hostdir,
    Passive     => 1,
    verbose     => 1,
} );

say "Beginning FTP download (this will take a few minutes)" if $verbose;
my $tarball = $ftpobj->get_specific_release( {
    release         => $release,
    path            => $localpath,
} );
croak "Tarball $tarball not found: $!" unless (-f $tarball);
say "FTP download concluded: see $tarball" if $verbose;

