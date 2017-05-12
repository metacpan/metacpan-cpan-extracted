=head1 NAME

Net::Download::Queue - Download files with one or more workers.

=head1 SYNOPSIS

  # *** In the app which needs to download files
  use Net::Download::Queue;
  my $oQueue = Net::Download::Queue->new() or die;
  my $oDownload = $oQueue->oDownloadAdd(
      "http://www.darserman.com/Perl/TexQL/texql.pl",
      "./downloads",
      "texql.pl.txt",
      $urlReferer,      #Optional
  ) or die;
  #The url is now queued


  # *** Or using the command line
  download_queue --url=http://www.darserman.com/Perl/TexQL/texql.pl \
      --dir=./downloads --file=texql.pl.txt --
  #The url is now queued



  # *** On another command line (you can have many of these)
  download_queue --process
  #Urls are downloaded as they appear in the queue


=head1 DESCRIPTION

Download files asynchronously in a queued fashion.

Your application (or a CLI script) can add files to the queue, and
other workes will process the queue and actually download the files.

=cut





package Net::Download::Queue;

use warnings;
use strict;

use File::Basename;

use LWP::UserAgent;
use HTTP::Response;
use HTTP::Request::Common qw(HEAD);

use Net::Download::Queue::DBI;
use Net::Download::Queue::Download;
use Net::Download::Queue::DownloadStatus;






our $VERSION = '0.04';



=head1 METHODS

=head2 new()

Create new queue.

=cut
sub new {
    my $self = bless {}, shift;

    return($self);
}





=head2 oDownloadAdd($url, $dirDownload, $file, [$urlReferer = ""])

Add $url to the queue, to be downloaded in $dirDownload/$file.

Return the new Download object on success, else die.

=cut
sub oDownloadAdd {
    my $self = shift;
    my ($url, $dirDownload, $file, $urlReferer) = @_;
    $urlReferer ||= "";

    return( Net::Download::Queue::Download->create({
        url => $url,
        dirDownload => $dirDownload,
        fileDownload => $file,
        urlReferer => $urlReferer,
    }) or die );

}





=head2 oDownloadDequeue()

If there is any pending download in the queue, return a Download
object, or return undef if there are no pending downloads.

The Download object is now in "downloading" state.

Die on errors.

=cut
sub oDownloadDequeue {
    my $self = shift;

    #Race condition, ignore that for now.
    my $oDownload = Net::Download::Queue::Download->search_first({
        download_status_id => Net::Download::Queue::Download->oDownloadStatus("queued"),
    }) or return(undef);

    $oDownload->setDownloading();
    #End race condition

    return($oDownload);
}





=head2 requeueDownloading()

Set any downloads in status "downloading" back into status "queued".

Die on errors.

=cut
sub requeueDownloading {
    my $self = shift;

    $_->setQueued() for(Net::Download::Queue::Download->retrieve_downloading);

    return(1);
}





=head2 percentComplete()

Return the percent 0..100 how complete the download of all current
downloads are.

If none is current, that's 100% complete.

Die on errors.

=cut
sub percentComplete {
    my $self = shift;

    my $currentCount = Net::Download::Queue::Download->sql_bytesSumCurrent->select_val or return(100);
    my $downloadingCount = Net::Download::Queue::Download->sql_bytesSumDownloading->select_val;
#    my $currentCount = Net::Download::Queue::Download->retrieve_current or return(100);
#    my $downloadingCount = Net::Download::Queue::Download->retrieve_downloading;
    
    my $percent = $downloadingCount / ($currentCount + $downloadingCount) * 100;

    return($percent);
}





=head1 CLASS METHODS

=head2 rebuildDatabase()

Empty and rebuild the SQLite database.

Return 1 on success, else die on errors.

=cut
sub rebuildDatabase {
    Net::Download::Queue::DBI->rebuildDatabase();
}





=head2 ensureDatabase()

Rebuild the SQLite database if it's not present.

Return 1 on success, else die on errors.

=cut
sub ensureDatabase {
    Net::Download::Queue::DBI->ensureDatabase();
}





1;





__END__


=head1 SEE ALSO

I haven't found any modules that perform the downloads asynchronously.


=head1 KNOWN BUGS

Ther is a race condition when dequeueing a Download from the
queue. Should run in a transaction.


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
