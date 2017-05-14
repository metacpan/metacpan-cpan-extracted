#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use Window;

sub addMail {
    my ( $model, $subject, $sender, $date) = @_;
    $model->insertRow(0);
    $model->setData($model->index(0, 0), Qt::Variant($subject));
    $model->setData($model->index(0, 1), Qt::Variant($sender));
    $model->setData($model->index(0, 2), Qt::Variant($date));
}

sub createMailModel {
    my ( $parent ) = @_;
    my $model = Qt::StandardItemModel(0, 3, $parent);

    $model->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::Object::tr('Subject)')));
    $model->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::Object::tr('Sender')));
    $model->setHeaderData(2, Qt::Horizontal(), Qt::Variant(Qt::Object::tr('Date')));

    addMail($model, 'Happy New Year!', 'Grace K. <grace@software-inc.com>',
            Qt::DateTime(Qt::Date(2006, 12, 31), Qt::Time(17, 03)));
    addMail($model, 'Radically new concept', 'Grace K. <grace@software-inc.com>',
            Qt::DateTime(Qt::Date(2006, 12, 22), Qt::Time(9, 44)));
    addMail($model, 'Accounts', 'pascale@nospam.com',
            Qt::DateTime(Qt::Date(2006, 12, 31), Qt::Time(12, 50)));
    addMail($model, 'Expenses', 'Joe Bloggs <joe@bloggs.com>',
            Qt::DateTime(Qt::Date(2006, 12, 25), Qt::Time(11, 39)));
    addMail($model, 'Re: Expenses', 'Andy <andy@nospam.com>',
            Qt::DateTime(Qt::Date(2007, 01, 02), Qt::Time(16, 05)));
    addMail($model, 'Re: Accounts', 'Joe Bloggs <joe@bloggs.com>',
            Qt::DateTime(Qt::Date(2007, 01, 03), Qt::Time(14, 18)));
    addMail($model, 'Re: Accounts', 'Andy <andy@nospam.com>',
            Qt::DateTime(Qt::Date(2007, 01, 03), Qt::Time(14, 26)));
    addMail($model, 'Sports', 'Linda Smith <linda.smith@nospam.com>',
            Qt::DateTime(Qt::Date(2007, 01, 05), Qt::Time(11, 33)));
    addMail($model, 'AW: Sports', 'Rolf Newschweinstein <rolfn@nospam.com>',
            Qt::DateTime(Qt::Date(2007, 01, 05), Qt::Time(12, 00)));
    addMail($model, 'RE: Sports', 'Petra Schmidt <petras@nospam.com>',
            Qt::DateTime(Qt::Date(2007, 01, 05), Qt::Time(12, 01)));

    return $model;
}

sub main {
    my $app = Qt::Application( \@ARGV );
    my $window = Window();
    $window->setSourceModel(createMailModel($window));
    $window->show();
    exit $app->exec();
}

main();
