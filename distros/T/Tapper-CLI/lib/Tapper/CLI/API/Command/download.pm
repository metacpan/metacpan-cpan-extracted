package Tapper::CLI::API::Command::download;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::API::Command::download::VERSION = '5.0.8';
use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use IO::Socket;
use Tapper::Config;
use File::Slurp 'slurp';
use Data::Dumper;
use Moose;

sub abstract {
        'Download a file from a report'
}

sub opt_spec {
        return (
                [ "verbose",         "some more informational output" ],
                [ "reportid=s",      "INT; the testrun id where the file is attached" ],
                [ "file=s",          "STRING; the filename to download" ],
                [ "nth=s",           "INT; the n-th file if there is more than one with same name; default 0" ],
                [ "saveas=s",        "STRING; where to write result; default print to STDOUT" ],
                [ "reportserver=s",  "STRING; use this host for upload" ],
                [ "reportport=s",    "STRING; use this port for upload" ],
               );
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "tapper-api dowload --reportid=s --file=s [ --saveas=s ] [ --nth=s ]";
}

sub _allowed_opts
{
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        # -- file constraints --
        my $file    = $opt->{file};
        say "Missing argument --file"                                  unless $file;

        # -- report constraints --
        my $reportid  = $opt->{reportid};
        my $report_ok = $reportid && $reportid =~ /^\d+$/;
        say "Missing argument --reportid"                              unless $reportid;
        say "Error: Strange target report (id '".($reportid//"")."')." unless $report_ok;

        return 1 if $opt->{reportid} && $report_ok;
        die $self->usage->text;
}

sub execute
{
        my ($self, $opt, $args) = @_;

        $self->download ($opt, $args);
}

sub download
{
        my ($self, $opt, $args) = @_;

        my $host = $opt->{reportserver} || Tapper::Config->subconfig->{report_server};
        my $port = $opt->{reportport}   || Tapper::Config->subconfig->{report_api_port};

        my $reportid    = $opt->{reportid};
        my $file        = $opt->{file};
        my $saveas      = $opt->{saveas};
        my $nth         = $opt->{nth} || 0;
        my $content;

        my $cmdline     = "#! download $reportid $file $nth\n";

        my $REMOTEAPI   = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port);
        if ($REMOTEAPI) {
                print $REMOTEAPI $cmdline;
                {
                        local $/;
                        $content = <$REMOTEAPI>;
                }
                close ($REMOTEAPI);

                # write to file or STDOUT
                if ($saveas) {
                        open my $SAVEAS, ">", $saveas or die "Can not write to file '$saveas'";
                        print $SAVEAS $content;
                        close $SAVEAS;
                } else {
                        print $content;
                }
        }
        else {
                say "Cannot open remote receiver $host:$port.";
        }
}

# perl -Ilib bin/tapper-api download --reportid=552 --file ~/xyz         --saveas=/tmp/myxyz
# perl -Ilib bin/tapper-api download --reportid=552 --file ~/xyz --nth=1 --saveas=/tmp/myxyz

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::API::Command::download

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
