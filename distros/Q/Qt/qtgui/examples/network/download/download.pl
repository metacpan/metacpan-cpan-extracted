#!/usr/bin/perl

package DownloadManager;

use strict;
use warnings;
use QtCore4;
use QtNetwork4;
use QtCore4::isa qw( Qt::Object );
use QtCore4::slots
    execute => [],
    downloadFinished => ['QNetworkReply *'];
use List::MoreUtils qw( first_index );

sub manager {
    return this->{manager};
}

sub currentDownloads {
    return this->{currentDownloads};
}

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{manager} = Qt::NetworkAccessManager();
    this->{currentDownloads} = [];
    this->connect(manager(), SIGNAL 'finished(QNetworkReply*)',
            SLOT 'downloadFinished(QNetworkReply*)');
}

sub doDownload
{
    my ($url) = @_;
    my $request = Qt::NetworkRequest($url);
    my $reply = manager()->get($request);

    push @{currentDownloads()}, $reply;
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

sub saveToDisk
{
    my ($filename, $data) = @_;
    my $file = Qt::File($filename);
    if (!$file->open(Qt::IODevice::WriteOnly())) {
        printf STDERR "Could not open %s for writing: %s\n",
                $filename,
                $file->errorString();
        return 0;
    }

    $file->write($data->readAll());
    $file->close();

    return 1;
}

sub execute
{
    my $args = Qt::CoreApplication::instance()->arguments();
    shift @{$args};
    if (scalar @{$args} == 0) {
        printf "Qt Download example - downloads all URLs in parallel\n" .
               "Usage: download url1 [url2... urlN]\n" .
               "\n" .
               "Downloads the URLs passed in the command-line to the local directory\n" .
               "If the target file already exists, a .0, .1, .2, etc. is appended to\n" .
               "differentiate.\n";
        Qt::CoreApplication::instance()->quit();
        return;
    }

    foreach my $arg ( @{$args} ) {
        my $url = Qt::Url::fromEncoded(Qt::ByteArray($arg));
        doDownload($url);
    }
}

sub downloadFinished
{
    my ($reply) = @_;
    my $url = $reply->url();
    if ($reply->error() != Qt::NetworkReply::NoError()) {
        printf STDERR "Download of %s failed: %s\n",
                $url->toEncoded()->constData(),
                $reply->errorString();
    } else {
        my $filename = saveFileName($url);
        if (saveToDisk($filename, $reply)) {
            printf "Download of %s succeded (saved to %s)\n",
                   $url->toEncoded()->constData(), $filename;
        }
    }

    my $index = first_index{ $_->Qt::base::getPointer == $reply->Qt::base::getPointer } @{currentDownloads()};
    splice @{currentDownloads()}, $index, 1;
    $reply->deleteLater();

    if (scalar @{currentDownloads()} == 0) {
        # all downloads finished
        Qt::CoreApplication::instance()->quit();
    }
}

package main;

use strict;
use warnings;
use QtCore4;
use DownloadManager;

sub main
{
    my $app = Qt::CoreApplication(\@ARGV);

    my $manager = DownloadManager();
    Qt::Timer::singleShot(0, $manager, SLOT 'execute()');

    return $app->exec();
}

exit main();
