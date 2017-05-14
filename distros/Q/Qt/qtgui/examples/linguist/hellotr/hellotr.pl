#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

# [1] //! [2]
sub main
# [1] //! [3] //! [4]
{
    my $app = Qt::Application(\@ARGV);
# [3]

# [5]
    my $translator = Qt::Translator();
# [5] //! [6]
    $translator->load('hellotr_la');
# [6] //! [7]
    $app->installTranslator($translator);
# [4] //! [7]

# [8]
    my $hello = Qt::PushButton(Qt::PushButton::tr("Hello world!"));
# [8]
    $hello->resize(100, 30);

    $hello->show();
    return $app->exec();
}
# [2]

exit main();
