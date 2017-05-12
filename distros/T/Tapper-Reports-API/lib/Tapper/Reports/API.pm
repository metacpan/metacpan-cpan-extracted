package Tapper::Reports::API;
# git description: v5.0.4-1-ga161e06

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Remote network API for result evaluation
$Tapper::Reports::API::VERSION = '5.0.5';
use 5.010;
use strict;
use warnings;

use parent 'Net::Server::Fork';

use Tapper::Reports::DPath::Mason;
use Tapper::Reports::DPath::TT;
use Tapper::Model 'model';
use Data::Dumper;


sub process_request
{
        my ($self) = @_;

        my $cmdline = <STDIN>;
        my ($cmd, @args) = _split_cmdline( $cmdline );
        no strict 'refs'; ## no critic (ProhibitNoStrict)
        $cmd       //= "TAP";
        my $handle   = "handle_$cmd";
        $self->$handle (@args);
}


sub handle_TAP
{
        my ($self, @args) = @_;

        #print STDERR "Unrecognized input, interpret as TAP, but: TAP reporting via this API not yet implemented\n";
        print STDERR "Unrecognized input.\n";
}


sub handle_download
{
        my ($self, $report_id, $filename, $index) = @_;

        $index ||= 0;
        my $asc_desc = $index < 0 ? '-desc' : '-asc';
        $index = abs $index;
        my %reportfilter = ();
        $reportfilter{report_id} = $report_id if $report_id;
        my $reportfile =
         model('TestrunDB')
          ->resultset('ReportFile')
           ->search ({ %reportfilter,
                       filename  => { like => $filename } },
                     { order_by  => { $asc_desc => 'id' } })
            ->slice($index, $index)->first;
        print $reportfile->filecontent if $reportfile;
}


sub get_payload
{
        my ($self, @args) = @_;

        # unite '<<' and EOFMARKER when whitespace separated, in order to fix confusion
        $args[-2] .= pop @args if $args[-2] && $args[-2] eq '<<';

        my $EOFMARKER;
        $EOFMARKER = $1 if $args[-1] =~ /<<(.*)/;
        return '' unless $EOFMARKER;

        # ----- read template -----

        my $line;
        my $payload = '';
        while ($line = <STDIN>)
        {
                last if ($line =~ /^$EOFMARKER\s*$/);
                $payload .= $line;
        }
        return $payload;

}


sub handle_tt
{
        my ($self, @args) = @_;
        do { print "Template Toolkit is not enabled\n"; return } unless Tapper::Config->subconfig->{reports_enable_tt};

        my %args = _parse_args(@args[0..$#args-1]);
        my $payload = $self->get_payload(@args);

        my $tt  = Tapper::Reports::DPath::TT->new (
                                                   debug           => $args{debug}           ? 1 : 0,
                                                   puresqlabstract => $args{puresqlabstract} ? 1 : 0,
                                                  );
          my $answer = $tt->render(template => $payload);

        print $answer;
}


sub handle_upload
{
        my ($self, $report_id, $filename, $contenttype) = @_;

        my $s_filecontent = '';
        $s_filecontent = do { local $/; <STDIN> };
        return model('TestrunDB')->resultset('ReportFile')->new({
                report_id   => $report_id,
                filename    => $filename,
                filecontent => $s_filecontent,
                contenttype => $contenttype || 'plain', # 'application/octet-stream',
        })->insert if length($s_filecontent);
}

sub _parse_args {
        my (@args) = @_;

        my %args = ();

        foreach (@args) {
                my ($k, $v) = split /=/;
                $k =~ s/^-+//;
                $args{$k} = $v;
        }
        return %args;
}


sub handle_mason
{
        my ($self, @args) = @_;
        do { print "Mason is not enabled. Set reports_enable_mason: 1 in ".Tapper::Config->subconfig->{_last_used_tapper_config_file}.".\n"; return } unless Tapper::Config->subconfig->{reports_enable_mason};

        my %args = _parse_args(@args[0..$#args-1]);
        my $payload = $self->get_payload(@args);

        my $mason  = Tapper::Reports::DPath::Mason->new (
                                                         debug           => $args{debug}           ? 1 : 0,
                                                         puresqlabstract => $args{puresqlabstract} ? 1 : 0,
                                                        );
        my $answer = $mason->render(template => $payload);

        print $answer;
}

sub _split_cmdline
{
        my ($cmdline) = @_;

        $cmdline =~ s/^\s+//;
        my @list = split (/\s+/, $cmdline);
        shift @list; # no shebang
        return @list;
}


sub post_process_request_hook
{
        my ($self) = @_;
}

1; # End of Tapper::Reports::API

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::API - Tapper - Remote network API for result evaluation

=head2 process_request

Initial hook called on incoming data, reads first line and calls
respective handler.

=head2 handle_TAP

Handler for incoming TAP.

=head2 handle_download

Handler for download request.

=head2 get_payload

Get the payload of an API request (the stuff after the first line).

=head2 handle_tt

Handler for TT query API requests.

=head2 handle_upload

Handler for upload requests.

=head2 handle_mason

Handler for TT query API requests.

=head2 post_process_request_hook

Hook called after processing, currrently a no-op.

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
