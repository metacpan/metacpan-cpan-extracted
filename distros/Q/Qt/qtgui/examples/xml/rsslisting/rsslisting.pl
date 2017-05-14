#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use RSSListing;

=begin

main.cpp

Provides the main function for the RSS news reader example.

    Create an application and a main widget. Open the main widget for
    user input, and exit with an appropriate return value when it is
    closed.

=cut

sub main
{
    my $app = Qt::Application(\@ARGV);
    print STDERR "The usage of Qt::Http is not recommended anymore, please use Qt::NetworkAccessManager.\n";
    my $rsslisting = RSSListing();
    $rsslisting->show();
    return $app->exec();
}

exit main();
