package AnalogClock;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use List::Util qw( min );

my $hourHand = [
    Qt::Point(7, 8),
    Qt::Point(-7, 8),
    Qt::Point(0, -40)
];

my $minuteHand = [
    Qt::Point(7, 8),
    Qt::Point(-7, 8),
    Qt::Point(0, -70)
];

# [0] //! [1]
sub NEW {
    my ( $class, $parent ) = @_;
# [0] //! [2]
    $class->SUPER::NEW( $parent );
# [2] //! [3]
# [3] //! [4]
    my $timer = Qt::Timer(this);
# [4] //! [5]
    this->connect($timer, SIGNAL 'timeout()', this, SLOT 'update()');
# [5] //! [6]
    $timer->start(1000);
# [6]

    this->setWindowTitle(this->tr("Analog Clock"));
    this->resize(200, 200);
# [7]
}
# [1] //! [7]

# [8] //! [9]
sub paintEvent {
# [8] //! [10]

    my $hourColor = Qt::Color(127, 0, 127);
    my $minuteColor = Qt::Color(0, 127, 127, 191);

    my $side = min(this->width(), this->height());
    my $time = Qt::Time::currentTime();
# [10]

# [11]
    my $painter = Qt::Painter(this);
# [11] //! [12]
    $painter->setRenderHint(Qt::Painter::Antialiasing());
# [12] //! [13]
    $painter->translate(this->width() / 2, this->height() / 2);
# [13] //! [14]
    $painter->scale($side / 200.0, $side / 200.0);
# [9] //! [14]

# [15]
    $painter->setPen(Qt::NoPen());
# [15] //! [16]
    $painter->setBrush(Qt::Brush($hourColor));
# [16]

# [17] //! [18]
    $painter->save();
# [17] //! [19]
    $painter->rotate(30.0 * (($time->hour() + $time->minute() / 60.0)));
    # XXX This should work by doing drawConvexPolygon( $hourHand, 3 ), but that
    # method seems to be incorrect in smoke.
    $painter->drawConvexPolygon(Qt::Polygon($hourHand));
    $painter->restore();
# [18] //! [19]

# [20]
    $painter->setPen($hourColor);
# [20] //! [21]

    for (my $i = 0; $i < 12; ++$i) {
        $painter->drawLine(88, 0, 96, 0);
        $painter->rotate(30.0);
    }
# [21]

# [22]
    $painter->setPen(Qt::NoPen());
# [22] //! [23]
    $painter->setBrush(Qt::Brush($minuteColor));

# [24]
    $painter->save();
    $painter->rotate(6.0 * ($time->minute() + $time->second() / 60.0));
    $painter->drawConvexPolygon(Qt::Polygon($minuteHand));
    $painter->restore();
# [23] //! [24]

# [25]
    $painter->setPen($minuteColor);
# [25] //! [26]

# [27]
    for (my $j = 0; $j < 60; ++$j) {
        if (($j % 5) != 0) {
            $painter->drawLine(92, 0, 96, 0);
        }
        $painter->rotate(6.0);
    }

    $painter->end();
# [27]
}
# [26]

1;
