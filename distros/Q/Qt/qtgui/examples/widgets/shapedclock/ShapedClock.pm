package ShapedClock;

use strict;
use warnings;

use List::Util qw( min );
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

# [0]
sub dragPosition() {
    return this->{dragPosition};
}
# [0]

my $hourHand = Qt::Polygon( [
    Qt::Point(7, 8),
    Qt::Point(-7, 8),
    Qt::Point(0, -40)
] );
my $minuteHand = Qt::Polygon( [
    Qt::Point(7, 8),
    Qt::Point(-7, 8),
    Qt::Point(0, -70)
] );

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent, Qt::FramelessWindowHint() | Qt::WindowSystemMenuHint());
    my $timer = Qt::Timer(this);
    this->connect($timer, SIGNAL 'timeout()', this, SLOT 'update()');
    $timer->start(1000);

    my $quitAction = Qt::Action(this->tr("E&xit"), this);
    $quitAction->setShortcut(Qt::KeySequence(this->tr("Ctrl+Q")));
    this->connect($quitAction, SIGNAL 'triggered()', qApp, SLOT 'quit()');
    this->addAction($quitAction);

    this->setContextMenuPolicy(Qt::ActionsContextMenu());
    this->setToolTip(this->tr("Drag the clock with the left mouse button.\n" .
                  "Use the right mouse button to open a context menu."));
    this->setWindowTitle(this->tr("Shaped Analog Clock"));
}
# [0]

# [1]
sub mousePressEvent {
    my ($event) = @_;
    if ($event->button() == Qt::LeftButton()) {
        this->{dragPosition} = Qt::Point($event->globalPos() - this->frameGeometry()->topLeft());
        $event->accept();
    }
}
# [1]

# [2]
sub mouseMoveEvent {
    my ($event) = @_;
    if ($event->buttons() & ${Qt::LeftButton()}) {
        this->move($event->globalPos() - this->dragPosition);
        $event->accept();
    }
}
# [2]

# [3]
sub paintEvent {
    my $hourColor = Qt::Color(127, 0, 127);
    my $minuteColor = Qt::Color(0, 127, 127, 191);

    my $side = min(this->width(), this->height());
    my $time = Qt::Time::currentTime();

    my $painter = Qt::Painter(this);
    $painter->setRenderHint(Qt::Painter::Antialiasing());
    $painter->translate(this->width() / 2, this->height() / 2);
    $painter->scale($side / 200.0, $side / 200.0);

    $painter->setPen(Qt::NoPen());
    $painter->setBrush(Qt::Brush($hourColor));

    $painter->save();
    $painter->rotate(30.0 * (($time->hour() + $time->minute() / 60.0)));
    $painter->drawConvexPolygon($hourHand);
    $painter->restore();

    $painter->setPen($hourColor);

    for (my $i = 0; $i < 12; ++$i) {
        $painter->drawLine(88, 0, 96, 0);
        $painter->rotate(30.0);
    }

    $painter->setPen(Qt::NoPen());
    $painter->setBrush(Qt::Brush($minuteColor));

    $painter->save();
    $painter->rotate(6.0 * ($time->minute() + $time->second() / 60.0));
    $painter->drawConvexPolygon($minuteHand);
    $painter->restore();

    $painter->setPen($minuteColor);

    for (my $j = 0; $j < 60; ++$j) {
        if (($j % 5) != 0){
            $painter->drawLine(92, 0, 96, 0);
        }
        $painter->rotate(6.0);
    }
    $painter->end();
}
# [3]

# [4]
sub resizeEvent {
    my $side = min(this->width(), this->height());
    my $maskedRegion = Qt::Region(this->width() / 2 - $side / 2, this->height() / 2 - $side / 2, $side,
                         $side, Qt::Region::Ellipse());
    this->setMask($maskedRegion);
}
# [4]

# [5]
sub sizeHint {
    return Qt::Size(100, 100);
}
# [5]

1;
