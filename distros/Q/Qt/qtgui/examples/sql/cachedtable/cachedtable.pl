#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use lib '../';
use Connection;
use TableEditor;

# [0]
sub main
{
    my $app = Qt::Application(\@ARGV);
    if (!Connection::createConnection()) {
        return 1;
    }

    my $editor = TableEditor('person');
    $editor->show();
    return $editor->exec();
}
# [0]

exit main();
