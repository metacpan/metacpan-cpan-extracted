#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use SecureSocketClientResources;
use SslClient;

sub main
{
    my $app = Qt::Application(\@ARGV);

    if (!Qt::SslSocket::supportsSsl()) {
        Qt::MessageBox::information(0, 'Secure Socket Client',
                'This system does not support OpenSSL.');
        return -1;
    }

    my $client = SslClient();
    $client->show();

    return $app->exec();
}

exit main();
