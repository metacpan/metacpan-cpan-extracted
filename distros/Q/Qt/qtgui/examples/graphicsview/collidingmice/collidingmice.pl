#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Mouse;

my $MouseCount = 7;

# [0]
sub main
{
    my $app = Qt::Application( \@ARGV );
    srand(Qt::Time(0,0,0)->secsTo(Qt::Time::currentTime()));
# [0]

# [1]
    my $scene = Qt::GraphicsScene();
    $scene->setSceneRect(-300, -300, 600, 600);
# [1] //! [2]
    $scene->setItemIndexMethod(Qt::GraphicsScene::NoIndex());
# [2]

# [3]
    for (my $i = 0; $i < $MouseCount; ++$i) {
        my $mouse = Mouse();
        $mouse->setPos(sin(($i * 6.28) / $MouseCount) * 200,
                       cos(($i * 6.28) / $MouseCount) * 200);
        $scene->addItem($mouse);
    }
# [3]

# [4]
    my $view = Qt::GraphicsView($scene);
    $view->setRenderHint(Qt::Painter::Antialiasing());
    $view->setBackgroundBrush(Qt::Brush(Qt::Pixmap('images/cheese.jpg')));
# [4] //! [5]
    $view->setCacheMode(Qt::GraphicsView::CacheBackground());
    $view->setViewportUpdateMode(Qt::GraphicsView::BoundingRectViewportUpdate());
    $view->setDragMode(Qt::GraphicsView::ScrollHandDrag());
# [5] //! [6]
    $view->setWindowTitle(Qt::GraphicsView::tr('Colliding Mice'));
    $view->resize(400, 300);
    $view->show();

    my $timer = Qt::Timer();
    Qt::Object::connect( $timer, SIGNAL 'timeout()', $scene, SLOT 'advance()' );
    $timer->start(1000 / 33);

    return $app->exec();
}
# [6]

exit main();
