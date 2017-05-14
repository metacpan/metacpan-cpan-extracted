#!/usr/bin/perl -w

use strict;

use QtCore4;
use QtGui4;

=begin

        ambiguous
        autoload
        calls
        gc
        signals
        slots
        verbose
);

=cut

use MainWindow;

=begin

sub dumpMetaMethods {
    my ( $meta ) = @_;

    print "Methods for ".$meta->className().":\n";
    foreach my $index ( 0..$meta->methodCount()-1 ) {
        my $metaMethod = $meta->method($index);
        print $metaMethod->signature() . "\n";
    }
    print "\n";
}

=cut

sub main {
    my $app = Qt::Application();
    my $mainWin = MainWindow();
    #dumpMetaMethods(Qt::_internal::getMetaObject('QMdiArea'));
    $mainWin->show();
    exit $app->exec();
}

main();
