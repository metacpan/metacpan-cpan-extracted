#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use AddressBook;

# [main function]
sub main
{
    my $app = Qt::Application(\@ARGV);

    my $addressBook = AddressBook();
    $addressBook->show();

    return $app->exec();
}
# [main function]

exit main();
