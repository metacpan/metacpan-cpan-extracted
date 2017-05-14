package TabletApplication;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Application );

sub setCanvas {
    my ($canvas) = @_;
    this->{myCanvas} = $canvas;
}

sub myCanvas() {
    return this->{myCanvas};
}

# [0]
sub event {
    my ($event) = @_;
    if ($event->type() == Qt::Event::TabletEnterProximity() ||
        $event->type() == Qt::Event::TabletLeaveProximity()) {
        CAST( $event, 'Qt::TabletEvent' );
        this->myCanvas->setTabletDevice(
            $event->device());
        return 1;
    }
    return this->SUPER::event($event);
}
# [0]

1;
