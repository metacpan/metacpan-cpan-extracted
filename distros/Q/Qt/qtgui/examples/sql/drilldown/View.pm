package View;

use strict;
use warnings;
use QtCore4;
use QtGui4;

use QtCore4::isa qw( Qt::GraphicsView );
use QtCore4::slots
    updateImage => ['int', 'const QString &'];

use InformationWindow;
use ImageItem;

# [0]
sub NEW
{
    my ($class, $offices, $images, $parent) = @_;
    $class->SUPER::NEW( $parent );
    this->{officeTable} = Qt::SqlRelationalTableModel(this);
    this->{officeTable}->setTable($offices);
    this->{officeTable}->setRelation(1, Qt::SqlRelation($images, 'locationid', 'file'));
    this->{officeTable}->select();
# [0]

# [1]
    this->{scene} = Qt::GraphicsScene(this);
    this->{scene}->setSceneRect(0, 0, 465, 615);
    this->setScene(this->{scene});

    this->addItems();

    my $logo = this->{scene}->addPixmap(Qt::Pixmap('logo.png'));
    $logo->setPos(30, 515);

    this->setMinimumSize(470, 620);
    this->setMaximumSize(470, 620);

    this->setWindowTitle(this->tr('Offices World Wide'));
}
# [1]

# [3]
sub addItems
{
    my $officeCount = this->{officeTable}->rowCount();

    my $imageOffset = 150;
    my $leftMargin = 70;
    my $topMargin = 40;

    foreach my $i ( 0..$officeCount-1 ) {
        my $image;
        my $label;
        my $record = this->{officeTable}->record($i);

        my $id = $record->value('id')->toInt();
        my $file = $record->value('file')->toString();
        my $location = $record->value('location')->toString();

        my $columnOffset = (sprintf( '%d', ($i / 3)) * 37);
        my $x = (sprintf( '%d', ($i / 3)) * $imageOffset) + $leftMargin + $columnOffset;
        my $y = (sprintf( '%d', ($i % 3)) * $imageOffset) + $topMargin;

        $image = ImageItem($id, Qt::Pixmap($file));
        $image->setData(0, Qt::Variant(Qt::Int($i)));
        $image->setPos($x, $y);
        this->{scene}->addItem($image);
        # XXX Remove this once Issue 22 is resolved.
        push @{this->{images}}, $image;

        $label = this->{scene}->addText($location);
        my $labelOffset = Qt::PointF((150 - $label->boundingRect()->width()) / 2, 120.0);
        $label->setPos(Qt::PointF($x, $y) + $labelOffset);
    }
}
# [3]

# [5]
sub mouseReleaseEvent
{
    my ($event) = @_;
    if (my $item = this->itemAt($event->pos())) {
        if ($item->isa('ImageItem')) {
            this->showInformation($item);
        }
    }
    this->SUPER::mouseReleaseEvent($event);
}
# [5]

# [6]
sub showInformation
{
    my ($image) = @_;
    my $id = $image->id();
    if ($id < 0 || $id >= this->{officeTable}->rowCount()) {
        return;
    }

    my $window = this->findWindow($id);
    if ($window && $window->isVisible()) {
        $window->raise();
        $window->activateWindow();
    } elsif ($window && !$window->isVisible()) {
        $window->show();
    } else {
        my $window = InformationWindow($id, this->{officeTable}, this);

        this->connect($window, SIGNAL 'imageChanged(int, QString)',
                this, SLOT 'updateImage(int, QString)');

        $window->move(this->pos() + Qt::Point(20, 40));
        $window->show();
        push @{this->{informationWindows}}, $window;
    }
}
# [6]

# [7]
sub updateImage
{
    my ($id, $fileName) = @_;
    my $items = this->{scene}->items();

    foreach my $item (@{$items}) {
        if ($item->isa('ImageItem')) {
            my $image = $item;
            if ($image->id() == $id){
                $image->setPixmap(Qt::Pixmap($fileName));
                $image->adjust();
                last;
            }
        }
    }
}
# [7]

# [8]
sub findWindow
{
    my ($id) = @_;
    foreach my $window ( @{this->{informationWindows}} ) {
        if ( $window->id() == $id ) {
            return $window;
        }
    }
    return;
}
# [8]

1;
