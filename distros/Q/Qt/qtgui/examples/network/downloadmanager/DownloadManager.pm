package DownloadManager;

use strict;
use warnings;
use QtCore4;
use QtNetwork4;
use QtCore4::isa qw( Qt::Object );
use TextProgressBar;
use QtCore4::signals
    finished => [];

use QtCore4::slots
    startNextDownload => [],
    downloadProgress => ['qint64', 'qint64'],
    downloadFinished => [],
    downloadReadyRead => [];

use Scalar::Util qw( reftype );

sub manager() {
    return this->{manager};
}

sub downloadQueue() {
    return this->{downloadQueue};
}

sub currentDownload() {
    return this->{currentDownload};
}

sub output() {
    return this->{output};
}

sub downloadTime() {
    return this->{downloadTime};
}

sub progressBar() {
    return this->{progressBar};
}

sub downloadedCount() {
    return this->{downloadedCount};
}

sub totalCount() {
    return this->{totalCount};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{downloadedCount} = 0;
    this->{totalCount} = 0;
    this->{manager} = Qt::NetworkAccessManager();
    this->{output} = Qt::File();
    this->{downloadTime} = Qt::Time();
    this->{progressBar} = TextProgressBar->new();
    this->{downloadQueue} = [];
}

sub append
{
    my ($url) = @_;
    if ( reftype( $url ) eq 'ARRAY' ) {
        foreach my $url2 ( @{$url} ) {
            append(Qt::Url::fromEncoded(Qt::ByteArray($url2)));
        }
        if (scalar @{downloadQueue()} == 0) {
            Qt::Timer::singleShot(0, this, SIGNAL 'finished()');
        }
        return;
    }

    if (scalar @{downloadQueue()} == 0) {
        Qt::Timer::singleShot(0, this, SLOT 'startNextDownload()');
    }
    push @{downloadQueue()}, $url;
    ++(this->{totalCount});
}

sub saveFileName
{
    my ($url) = @_;
    my $path = $url->path();
    my $basename = Qt::FileInfo($path)->fileName();

    if (!defined $basename) {
        $basename = 'download';
    }

    if (Qt::File::exists($basename)) {
        # already exists, don't overwrite
        my $i = 0;
        $basename .= '.';
        while (Qt::File::exists($basename . $i)) {
            ++$i;
        }

        $basename .= $i;
    }

    return $basename;
}

sub startNextDownload
{
    if (scalar @{downloadQueue()} == 0) {
        printf "%d/%d files downloaded successfully\n", downloadedCount(), totalCount();
        emit finished();
        return;
    }

    my $url = shift @{downloadQueue()};

    my $filename = saveFileName($url);
    output()->setFileName($filename);
    if (!output()->open(Qt::IODevice::WriteOnly())) {
        printf STDERR "Problem opening save file '%s' for download '%s': %s\n",
               $filename, $url->toEncoded()->constData(),
               output()->errorString();

        startNextDownload();
        return;                 # skip this download
    }

    my $request = Qt::NetworkRequest($url);
    this->{currentDownload} = manager()->get($request);
    this->connect(currentDownload, SIGNAL 'downloadProgress(qint64,qint64)',
            SLOT 'downloadProgress(qint64,qint64)');
    this->connect(currentDownload, SIGNAL 'finished()',
            SLOT 'downloadFinished()');
    this->connect(currentDownload, SIGNAL 'readyRead()',
            SLOT 'downloadReadyRead()');

    # prepare the output
    printf "Downloading %s...\n", $url->toEncoded()->constData();
    downloadTime()->start();
}

sub downloadProgress
{
    my ($bytesReceived, $bytesTotal) = @_;
    progressBar()->setStatus($bytesReceived, $bytesTotal);

    # calculate the download speed
    my $speed = $bytesReceived * 1000.0 / downloadTime()->elapsed();
    my $unit;
    if ($speed < 1024) {
        $unit = 'bytes/sec';
    } elsif ($speed < 1024*1024) {
        $speed /= 1024;
        $unit = 'kB/s';
    } else {
        $speed /= 1024*1024;
        $unit = 'MB/s';
    }

    progressBar()->setMessage(sprintf '%03f %s', $speed, $unit);
    progressBar()->update();
}

sub downloadFinished
{
    progressBar()->clear();
    output()->close();

    if (currentDownload->error() != Qt::NetworkReply::NoError()) {
        # download failed
        printf STDERR "Failed: %s\n", currentDownload->errorString();
    } else {
        printf "Succeeded.\n";
        ++(this->{downloadedCount});
    }

    startNextDownload();
}

sub downloadReadyRead
{
    output()->write(currentDownload->readAll());
}

1;
