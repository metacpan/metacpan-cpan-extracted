package ImageItemObject;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Scalar::Util qw(weaken);

use QtCore4::isa qw( Qt::Object );
use QtCore4::slots
    setFrame => ['int'],
    updateItemPosition => [];

sub NEW {
    shift->SUPER::NEW(@_);
}

sub setImageItem {
    this->{imageItem} = shift;
    weaken(this->{imageItem});
    return;
}

# [3]
sub setFrame
{
    my ($frame) = @_;
    this->{imageItem}->adjust();
    my $center = this->{imageItem}->boundingRect()->center();

    this->{imageItem}->translate($center->x(), $center->y());
    this->{imageItem}->scale(1 + $frame / 330.0, 1 + $frame / 330.0);
    this->{imageItem}->translate(-($center->x()), -($center->y()));
}
# [3]

# [6]
sub updateItemPosition
{
    this->{imageItem}->setZValue(this->{z});
}
# [6]

package ImageItem;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::GraphicsPixmapItem );
use ImageItemObject;

# [0]
sub NEW {
    my ($class, $id, $pixmap, $parent, $scene) = @_;
    $class->SUPER::NEW($pixmap, $parent, $scene);

    my $object = ImageItemObject($parent);
    $object->setImageItem( this );
    this->{object} = $object;

    this->{z} = 0.0;

    this->{recordId} = $id;
    this->setAcceptsHoverEvents(1);

    this->{timeLine} = Qt::TimeLine();
    this->{timeLine}->setDuration(150);
    this->{timeLine}->setFrameRange(0, 150);

    $object->connect(this->{timeLine}, SIGNAL 'frameChanged(int)', $object, SLOT 'setFrame(int)');
    $object->connect(this->{timeLine}, SIGNAL 'finished()', $object, SLOT 'updateItemPosition()');

    this->adjust();
}
# [0]

# [1]
sub hoverEnterEvent
{
    this->{timeLine}->setDirection(Qt::TimeLine::Forward());

    if (this->{z} != 1.0) {
        this->{z} = 1.0;
        this->{object}->updateItemPosition();
    }

    if (this->{timeLine}->state() == Qt::TimeLine::NotRunning()) {
        this->{timeLine}->start();
    }
}
# [1]

# [2]
sub hoverLeaveEvent
{
    this->{timeLine}->setDirection(Qt::TimeLine::Backward());
    if (this->{z} != 0.0) {
        this->{z} = 0.0;
    }

    if (this->{timeLine}->state() == Qt::TimeLine::NotRunning()) {
        this->{timeLine}->start();
    }
}
# [2]

# [4]
sub adjust
{
    my $matrix = Qt::Matrix();
    $matrix->scale(150/ this->boundingRect()->width(), 120/ this->boundingRect()->height());
    this->setMatrix($matrix);
}
# [4]

# [5]
sub id
{
    return this->{recordId};
}
# [5]

1;
