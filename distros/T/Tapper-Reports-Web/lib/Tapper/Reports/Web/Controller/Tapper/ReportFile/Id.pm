package Tapper::Reports::Web::Controller::Tapper::ReportFile::Id;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::ReportFile::Id::VERSION = '5.0.13';
use parent 'Tapper::Reports::Web::Controller::Base';
use HTML::FromANSI ();

use common::sense;
## no critic (RequireUseStrict)

#use HTML::FromANSI (); # avoid exports if using OO

our $ANSI2HTML_PRE  = '<link rel="stylesheet" type="text/css" title="Red" href="/tapper/static/css/style_red.css" /><body style="background: black;">';
our $ANSI2HTML_POST = '</body>';

sub index :Path :CaptureArgs(2)
{
        my ( $self, $c, $file_id, $viewmode ) = @_;
        $c->stash->{reportfile} = $c->model('TestrunDB')->resultset('ReportFile')->find($file_id);

        if (not $c->stash->{reportfile})
        {
                $c->response->content_type ("text/plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="nonexistent.reportfile.'.$file_id.'"');
                $c->response->body ("Error: File with id $file_id does not exist.");
        }
        elsif (not $c->stash->{reportfile}->filecontent)
        {
                $c->response->content_type ("text/plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="empty.reportfile.'.$file_id.'"');
                $c->response->body ("Error: File with id $file_id is empty.");
        }
        else
        {
                my $contenttype = $c->stash->{reportfile}->contenttype eq 'plain' ? 'text/plain' : $c->stash->{reportfile}->contenttype;
                my $disposition = $contenttype =~ /plain/ ? 'inline' : 'attachment';
                $c->response->content_type ($contenttype || 'application/octet-stream');

                my $filename = $c->stash->{reportfile}->filename;
                my @filecontent;
                my $content_disposition;

                if ( $viewmode eq 'ansi2txt' ) {
                        $filename    =~ s,[./],_,g if $disposition eq 'inline';
                        $filename   .=  '.txt';
                        @filecontent =  ansi_to_txt($c->stash->{reportfile}->filecontent);

                } elsif ( $viewmode eq 'ansi2html' ) {
                        $filename    =~ s,[./],_,g if $disposition eq 'inline';
                        $filename   .=  '.html';
                        my $a2h = HTML::FromANSI->new(style => '', font_face => '');
                        @filecontent =  $ANSI2HTML_PRE.$a2h->ansi_to_html($c->stash->{reportfile}->filecontent).$ANSI2HTML_POST;
                        $c->response->content_type('text/html');
                } else {
                        @filecontent =  $c->stash->{reportfile}->filecontent;
                }
                my $filecontent = join '', @filecontent;
                $filecontent    =~ s/ +$//mg if $viewmode eq 'ansi2html' or $viewmode eq 'ansi2txt';
                $c->response->header ("Content-Disposition" => qq($disposition; filename="$filename"));
                $c->response->body ($filecontent);
        }
}

# strip known ANSI sequences and special characters
# usually used in console output
sub ansi_to_txt {
        my ($filecontent) = @_;

        $filecontent =~ s/\e\[?.*?[\@-~](?:\?\d\d[hl])?//g;
        $filecontent =~ s,(?:\n\r)+,\n,g;
        $filecontent =~ s,\r(?!\n), ,g;
        $filecontent =~ s,[]+, ,g;
        return $filecontent;
}

sub filter
{
        my @retval;
        foreach my $line (@_) {
                $line =~ s/\000//g;
                $line =~ s/\015//g;
                $line =~ s/\033\[.*?[mH]//g;
                $line =~ s/\033\d+/\t/g;
                $line =~ s/\017//g;
                $line =~ s/\033\[\?25h//g;
                push @retval, $line;
        }
        return @retval;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::ReportFile::Id

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
