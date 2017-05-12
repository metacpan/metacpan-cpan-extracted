=head1 NAME

Net::Download::Queue::Download

=head1 SYNOPSIS


=cut





package Net::Download::Queue::Download;
use base 'Net::Download::Queue::DBI';



our $VERSION = Net::Download::Queue::DBI::VERSION;



use strict;
use Data::Dumper;

use File::Path;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Request::Common qw(GET POST);
use File::Slurp;





=head1 CLASS DBI STUFF

=cut

__PACKAGE__->set_up_table('download');
__PACKAGE__->has_a( download_status_id => 'Net::Download::Queue::DownloadStatus' );





=head2 trigger: before_create

Set domain and bytesContent.

=cut
__PACKAGE__->add_trigger(
    before_create => sub {
        my $self = shift;
        $self->domain($self->domainFromUrl($self->url));
        $self->_attribute_set("bytes_content", $self->bytesContentFromUrl($self->_attrs("url"), $self->_attrs("urlReferer")));
    }
);





=head2 retrieve_current

Return array with all current downloads.

=cut
__PACKAGE__->add_constructor(
    retrieve_current => q{
        download_status_id in (
            select status_id from download_status where is_current = 1
        )
});





=head2 retrieve_downloading

Return array with all downloading downloads.

=cut
__PACKAGE__->add_constructor(
    retrieve_downloading => q{
        download_status_id in (
            select status_id from download_status where name = 'downloading'
        )
});





=head2 sql_bytesSumCurrent->select_val

Return total size of current downloads.

=cut
__PACKAGE__->set_sql(bytesSumCurrent => q{
    select sum(bytes_content) from __TABLE__ where download_status_id in (
            select status_id from download_status where is_current = 1
        )
});





=head2 sql_bytesSumDownloading->select_val

Return total size of downloading downloads.

=cut
__PACKAGE__->set_sql(bytesSumDownloading => q{
    select sum(bytes_content) from __TABLE__ where download_status_id in (
            select status_id from download_status where name = 'downloading'
        )
});





=head1 METHODS


=head2 setDone()

Set the download status to download done ok. Set the bytesDownloaded
to bytesContent.

Return 1, die on errors.

=cut
sub setDone {
    my $self = shift;

    $self->downloadStatusId($self->oDownloadStatus("downloaded: ok"));
    $self->bytesDownloaded( $self->bytesContent );
    $self->update();

	return(1);
}





=head2 setQueued()

Set the download status to queued.

Return 1, die on errors.

=cut
sub setQueued {
    my $self = shift;

    $self->downloadStatusId($self->oDownloadStatus("queued"));
    $self->update();

	return(1);
}





=head2 setDownloading()

Set the download status to downloading.

Return 1, die on errors.

=cut
sub setDownloading {
    my $self = shift;

    $self->downloadStatusId($self->oDownloadStatus("downloading"));
    $self->bytesDownloaded(0);
    $self->update();

	return(1);
}





=head2 setBytesDownloaded($bytesTotal)

Set the total number of bytes downloaded in this download.

Return 1, die on errors.

=cut
sub setBytesDownloaded {
    my $self = shift;
    my ($bytesDownloaded) = @_;

    $self->bytesDownloaded($bytesDownloaded);
    $self->update();

	return(1);
}





=head2 download([$rsStart], [$rsReceived], [$rsCheckCancel])

Attempt to perform download and set the status accordingly.

Perform the download regardless of the current status.

$rsStart, $rsReceived, $rsCheckCancel are sub refs which are called
during the download.

  $rsStart->($contentLength)
  Called once.

  $rsReceived->($bytesReceived)
  Called for each chunk downloaded.

  $rsCheckCancel->()
  Called for each chunk. Should return true if the download should be
  cancelled, else false.

Return 1, die on errors.

=cut
sub download {
    my $self = shift;
    my ($rsStart, $rsReceived, $rsCheckCancel) = @_;
    $rsStart ||= sub {};
    $rsReceived ||= sub {};
    $rsCheckCancel ||= sub {};
    my $updateEvery = 1000;

    eval {
        my $url = $self->url;

        my $oBrowser = LWP::UserAgent->new(
            env_proxy  => 0,
            timeout    => 50,
            keep_alive => 1,
            agent => "Internet Explorer 5.5 on Windows 2000: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0)",
        );
        my $oRequest = HTTP::Request->new(GET => $url);
        $self->urlReferer and $oRequest->referer($self->urlReferer);

        my $content = "";
        my $once = 0;
        my $bytesReceived = 0;
        my $oResponse = $oBrowser->request(
            $oRequest,
            sub {
                my ($chunk, $oResponse) = @_;

                $once++ or $rsStart->($oResponse->content_length || 1);

                $bytesReceived += length($chunk);
                $rsReceived->($bytesReceived || 1);

                $content .= $chunk;

                $rsCheckCancel->() and die("Cancelled\n");

                $once % $updateEvery or $self->setBytesDownloaded($bytesReceived);
            }
        );

        $oResponse->is_success or die("Could not get url ($url) (" . $oResponse->status_line . ")\n");
        defined($content) or warn("Could not get URL ($url) (no content)\n"), return(0);


        my $nameDir = $self->dirDownload();
        my $nameFile = "$nameDir/" . $self->fileDownload;

        mkpath($nameDir);
        -d $nameDir or warn("No dir ($nameDir)\n"), return(0);

        write_file($nameFile, { binmode => ":raw", }, $content);

        undef $content;

    };

    $self->setDone;

    $@ and die;

	return(1);
}





=head1 CLASS METHODS

=head2 domainFromUrl($url)

Return the domain part of $url, or "" if none was found.

Die on errors.

=cut
sub domainFromUrl {
    my $pkg = shift;
    my ($url) = @_;

    $url =~ m|^\w+ : // (?: [^\@]+ \@  )? ([\w\.]+)  |msx or return("");
    my $domain = $1;

	return($domain);
}





=head2 bytesContentFromUrl($url, [$urlReferer = ""])

Return the Content-Length of HEAD $url, or 0 if none was found.

Die on errors.

=cut
sub bytesContentFromUrl {
    my $pkg = shift;
    my ($url, $urlReferer) = @_;
    $urlReferer ||= "";

    my $oBrowser = LWP::UserAgent->new(
        env_proxy  => 0,
        timeout    => 50,
        keep_alive => 1,
        agent => "Internet Explorer 5.5 on Windows 2000: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0)",
    );
    my $oRequest = HTTP::Request->new(HEAD => $url);
    $urlReferer and $oRequest->referer($urlReferer);
    my $oResponse = $oBrowser->request($oRequest);
    $oResponse->is_success or return(0);
    return( $oResponse->header("Content-Length") || 0 );
}





1;





__END__

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-download-queue@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Download-Queue>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
