#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use DownloadManager;

sub main
{
    my $app = Qt::CoreApplication(\@ARGV);
    my $arguments = $app->arguments();
    shift @{$arguments};      # remove the first argument, which is the program's name

    if (scalar @{$arguments} == 0) {
        printf "Qt Download example\n" .
               "Usage: downloadmanager url1 [url2... urlN]\n" .
               "\n" .
               "Downloads the URLs passed in the command-line to the local directory\n" .
               "If the target file already exists, a .0, .1, .2, etc. is appended to\n" .
               "differentiate.\n";
        return 0;
    }

    my $manager = DownloadManager();
    $manager->append($arguments);

    Qt::Object::connect($manager, SIGNAL 'finished()', $app, SLOT 'quit()');
    return $app->exec();
}

exit main();
