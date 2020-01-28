package Tapper::CLI::API::Command::upload;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::API::Command::upload::VERSION = '5.0.6';
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
        'Upload and attach a file to a report'
}

sub opt_spec {
        return (
                [ "verbose",         "some more informational output" ],
                [ "reportid=s",      "INT; the testrun id to change", ],
                [ "file=s",          "STRING; the file to upload, use '-' for STDIN", ],
                [ "filename=s",      "STRING; alternate file name, especially when reading from STDIN", ],
                [ "reportserver=s",  "STRING; use this host for upload", ],
                [ "reportport=s",    "STRING; use this port for upload", ],
                [ "contenttype=s",   "STRING; content-type, default 'plain', use 'application/octet-stream' for binaries", ],
               );
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "tapper-api upload --reportid=s --file=s [ --contenttype=s ]";
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
        my $file_ok = $file && ($file eq '-' || -r $file);
        say "Missing argument --file"                                  unless $file;
        say "Error: file '".($file//"")."' must be readable or STDIN." unless $file_ok;

        # -- report constraints --
        my $reportid  = $opt->{reportid};
        my $report_ok = $reportid && $reportid =~ /^\d+$/;
        say "Missing argument --reportid"                              unless $reportid;
        say "Error: Strange target report (id '".($reportid//"")."')." unless $report_ok;

        return 1 if $opt->{reportid} && $file_ok && $report_ok;
        die $self->usage->text;
}

sub execute
{
        my ($self, $opt, $args) = @_;

        $self->upload ($opt, $args);
}

sub _read_file
{
        my ($self, $opt, $args) = @_;

        my $file = $opt->{file};
        my $content;

        # read from file or STDIN if filename == '-'
        if ($file eq '-') {
                $content = slurp (\*STDIN);
        } else {
                $content = slurp ($file);
        }
        return $content;
}


sub upload
{
        my ($self, $opt, $args) = @_;

        my $host = $opt->{reportserver} || Tapper::Config->subconfig->{report_server};
        my $port = $opt->{reportport}   || Tapper::Config->subconfig->{report_api_port};

        my $reportid    = $opt->{reportid};
        my $file        = $opt->{file};
        my $filename    = $opt->{filename};
        my $contenttype = $opt->{contenttype} || 'plain';
        my $content     = $self->_read_file($opt, $args);

        my $cmdline     = "#! upload $reportid ".($filename || $file)." $contenttype\n";

        my $REMOTEAPI   = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port);
        if ($REMOTEAPI) {
                #my $oldfh       = select $REMOTEAPI;
                print $REMOTEAPI $cmdline;
                print $REMOTEAPI $content;
                #select($oldfh);
                close ($REMOTEAPI);
        }
        else {
                say "Cannot open remote receiver $host:$port.";
        }
}

# perl -Ilib bin/tapper-api upload --reportid=552 --file ~/xyz
# perl -Ilib bin/tapper-api upload --reportid=552 --file=$HOME/xyz
# dmesg | perl -Ilib bin/tapper-api upload --reportid=552 --file=- --filename="dmesg"

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::API::Command::upload

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
