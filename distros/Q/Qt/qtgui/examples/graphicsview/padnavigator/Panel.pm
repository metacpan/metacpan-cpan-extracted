package Panel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtOpenGL4;
use QtCore4::isa qw( Qt::GraphicsView );
use QtCore4::slots
    updateSelectionStep => ['qreal'],
    updateFlipStep => ['qreal'],
    flip => [];
use constant { RAND_MAX => 2147483647 };

sub scene() {
    return this->{scene};
}

sub selectionItem() {
    return this->{selectionItem};
}

sub baseItem() {
    return this->{baseItem};
}

sub backItem() {
    return this->{backItem};
}

sub splash() {
    return this->{splash};
}

sub selectionTimeLine() {
    return this->{selectionTimeLine};
}

sub flipTimeLine() {
    return this->{flipTimeLine};
}

sub selectedX() {
    return this->{selectedX};
}

sub selectedY() {
    return this->{selectedY};
}

sub grid() {
    return this->{grid};
}

sub startPos() {
    return this->{startPos};
}

sub endPos() {
    return this->{endPos};
}

sub xrot() {
    return this->{yrot};
}

sub yrot() {
    return this->{yrot};
}

sub yrot2() {
    return this->{yrot2};
}

sub width() {
    return this->{width};
}

sub height() {
    return this->{height};
}

sub flipped() {
    return this->{flipped};
}

sub flipLeft() {
    return this->{flipLeft};
}

sub ui() {
    return this->{ui};
}

use RoundRectItem;
use SplashItem;
use Ui_BackSide;

sub NEW
{
    my ($class, $width, $height) = @_;
    $class->SUPER::NEW();
    this->{selectedX} = 0;
    this->{selectedY} = 0;
    this->{width} = $width;
    this->{height} = $height;
    this->{flipped} = 0;
    this->{flipLeft} = 1;

    setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff());
    setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff());
    setCacheMode(CacheBackground());
    setViewportUpdateMode(FullViewportUpdate());
    setRenderHints(Qt::Painter::Antialiasing() | Qt::Painter::SmoothPixmapTransform()
                   | Qt::Painter::TextAntialiasing());
    setBackgroundBrush(Qt::Brush(Qt::Pixmap('images/blue_angle_swirl.jpg')));
#ifndef QT_NO_OPENGL
    setViewport(Qt::GLWidget(Qt::GLFormat(Qt::GL::SampleBuffers())));
#endif
    setMinimumSize(50, 50);

    this->{selectionTimeLine} = Qt::TimeLine(150, this);
    this->{flipTimeLine} = Qt::TimeLine(500, this);

    my $bounds = Qt::RectF((-width() / 2.0) * 150, (-$height / 2.0) * 150, width * 150, $height * 150);

    this->{scene} = Qt::GraphicsScene($bounds, this);
    this->scene->setItemIndexMethod(Qt::GraphicsScene::NoIndex());
    setScene(this->scene);

    this->{baseItem} = RoundRectItem($bounds, Qt::Color(226, 255, 92, 64));
    scene->addItem(baseItem);

    my $embed = Qt::Widget();
    this->{ui} = Ui_BackSide->setupUi($embed);
    ui->hostName->setFocus();

    this->{backItem} = RoundRectItem($bounds, $embed->palette()->window(), $embed);
    backItem->setTransform(Qt::Transform()->rotate(180, Qt::YAxis()));
    backItem->setParentItem(baseItem);
        
    this->{selectionItem} = RoundRectItem(Qt::RectF(-60, -60, 120, 120), Qt::Color(Qt::gray()));
    selectionItem->setParentItem(baseItem);
    selectionItem->setZValue(-1);
    selectionItem->setPos(this->posForLocation(0, 0));
    this->{startPos} = selectionItem->pos();
    this->{endPos} = Qt::PointF();

    this->{grid} = [];
    for (my $y = 0; $y < $height; ++$y) {
        this->{grid}->[$y] = [];

        for (my $x = 0; $x < $width; ++$x) {
            my $item = RoundRectItem(Qt::RectF(-54, -54, 108, 108),
                                                    Qt::Color(214, 240, 110, 128));
            $item->setPos(posForLocation($x, $y));
                
            $item->setParentItem(baseItem);
            $item->setFlag(Qt::GraphicsItem::ItemIsFocusable());
            this->grid->[$y]->[$x] = $item;

            my $rand = rand(RAND_MAX) % 9;
            if ($rand == 0) { $item->setPixmap(Qt::Pixmap('images/kontact_contacts.png')); }
            elsif ($rand == 1) { $item->setPixmap(Qt::Pixmap('images/kontact_journal.png')); }
            elsif ($rand == 2) { $item->setPixmap(Qt::Pixmap('images/kontact_notes.png')); }
            elsif ($rand == 3) { $item->setPixmap(Qt::Pixmap('images/kopeteavailable.png')); }
            elsif ($rand == 4) { $item->setPixmap(Qt::Pixmap('images/metacontact_online.png')); }
            elsif ($rand == 5) { $item->setPixmap(Qt::Pixmap('images/minitools.png')); }
            elsif ($rand == 6) { $item->setPixmap(Qt::Pixmap('images/kontact_journal.png')); }
            elsif ($rand == 7) { $item->setPixmap(Qt::Pixmap('images/kontact_contacts.png')); }
            elsif ($rand == 8) { $item->setPixmap(Qt::Pixmap('images/kopeteavailable.png')); }

            this->connect($item->object, SIGNAL 'activated()', this, SLOT 'flip()');
        }
    }

    grid->[0]->[0]->setFocus();

    this->connect(backItem->object, SIGNAL 'activated()',
            this, SLOT 'flip()');
    this->connect(selectionTimeLine, SIGNAL 'valueChanged(qreal)',
            this, SLOT 'updateSelectionStep(qreal)');
    this->connect(flipTimeLine, SIGNAL 'valueChanged(qreal)',
            this, SLOT 'updateFlipStep(qreal)');

    this->{splash} = SplashItem();
    splash->setZValue(5);
    splash->setPos(-splash()->rect()->width() / 2, scene->sceneRect()->top());
    scene->addItem(splash);

    splash->grabKeyboard();
    
    updateSelectionStep(0);

    setWindowTitle(this->tr('Pad Navigator Example'));
}

sub keyPressEvent
{
    my ($event) = @_;
    if (splash->isVisible() || $event->key() == Qt::Key_Return() || flipped) {
        this->SUPER::keyPressEvent($event);
        return;
    }

    this->{selectedX} = (selectedX + width + ($event->key() == Qt::Key_Right()) - ($event->key() == Qt::Key_Left())) % width;
    this->{selectedY} = (selectedY + height + ($event->key() == Qt::Key_Down()) - ($event->key() == Qt::Key_Up())) % height;
    grid->[selectedY]->[selectedX]->setFocus();
    
    selectionTimeLine->stop();
    this->{startPos} = selectionItem->pos();
    this->{endPos} = posForLocation(selectedX, selectedY);
    selectionTimeLine->start();
}

sub resizeEvent
{
    my ($event) = @_;
    this->SUPER::resizeEvent($event);
    fitInView(scene->sceneRect(), Qt::KeepAspectRatio());
}

sub updateSelectionStep
{
    my ($val) = @_;
    my $newPos = Qt::PointF(startPos->x() + (endPos - startPos)->x() * $val,
                   startPos->y() + (endPos - startPos)->y() * $val);
    selectionItem->setPos($newPos);
    
    my $transform = Qt::Transform();
    this->{yrot} = $newPos->x() / 6.0;
    this->{xrot} = $newPos->y() / 6.0;
    $transform->rotate($newPos->x() / 6.0, Qt::YAxis());
    $transform->rotate($newPos->y() / 6.0, Qt::XAxis());
    baseItem->setTransform($transform);
}

sub updateFlipStep
{
    my ($val) = @_;
    my $finalxrot = xrot - xrot * $val;
    my $finalyrot;
    if (flipLeft) {
        $finalyrot = yrot - yrot * $val - 180 * $val;
    }
    else {
        $finalyrot = yrot - yrot * $val + 180 * $val;
    }
    my $transform = Qt::Transform();
    $transform->rotate($finalyrot, Qt::YAxis());
    $transform->rotate($finalxrot, Qt::XAxis());
    my $scale = 1 - sin(3.14 * $val) * 0.3;
    $transform->scale($scale, $scale);
    baseItem->setTransform($transform);
    if ($val == 0) {
        grid->[selectedY]->[selectedX]->setFocus();
    }
}

sub flip
{
    if (flipTimeLine->state() == Qt::TimeLine::Running()) {
        return;
    }

    if (flipTimeLine->currentValue() == 0) {
        flipTimeLine->setDirection(Qt::TimeLine::Forward());
        flipTimeLine->start();
        this->{flipped} = 1;
        this->{flipLeft} = selectionItem->pos()->x() < 0;
    } else {
        flipTimeLine->setDirection(Qt::TimeLine::Backward());
        flipTimeLine->start();
        this->{flipped} = 0;
    }
}

sub posForLocation
{
    my ($x, $y) = @_;
    return Qt::PointF($x * 150, $y * 150)
        - Qt::PointF((width - 1) * 75, (height - 1) * 75);
}

1;
