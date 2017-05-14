package ColorItem;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::GraphicsItem );

use constant RAND_MAX => 2147483647;

sub NEW {
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{color} = Qt::Color( rand(RAND_MAX) % 256, rand(RAND_MAX) % 256, rand(RAND_MAX) % 256 );
    this->setToolTip(sprintf "Qt::Color(%d, %d, %d)\n%s",
              this->{color}->red(), this->{color}->green(), this->{color}->blue(),
              'Click and drag this color onto the robot!');
    this->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
}

sub boundingRect
{
    return Qt::RectF(-15.5, -15.5, 34, 34);
}

sub paint
{
    my ($painter) = @_;
    $painter->setPen(Qt::NoPen());
    $painter->setBrush(Qt::Brush(Qt::darkGray()));
    $painter->drawEllipse(-12, -12, 30, 30);
    $painter->setPen(Qt::Pen(Qt::Brush(Qt::Color(Qt::black())), 1));
    $painter->setBrush(Qt::Brush(this->{color}));
    $painter->drawEllipse(-15, -15, 30, 30);
}

sub mousePressEvent
{
    my ($event) = @_;
    if ($event->button() != Qt::LeftButton()) {
        $event->ignore();
        return;
    }

    this->setCursor(Qt::Cursor(Qt::ClosedHandCursor()));
}

sub mouseMoveEvent
{
    my ($event) = @_;
    if (Qt::LineF(Qt::PointF($event->screenPos()), Qt::PointF($event->buttonDownScreenPos(Qt::LeftButton())))
        ->length() < Qt::Application::startDragDistance()) {
        return;
    }

    my $drag = Qt::Drag($event->widget());
    my $mime = Qt::MimeData();
    $drag->setMimeData($mime);

    my $n = 0;
    if ($n++ > 2 && (rand(RAND_MAX) % 3) == 0) {
        my $image = Qt::Image('images/head.png');
        $mime->setImageData($image);

        $drag->setPixmap(Qt::Pixmap::fromImage($image)->scaled(30, 40));
        $drag->setHotSpot(Qt::Point(15, 30));
    } else {
        $mime->setColorData(Qt::qVariantFromValue(this->{color}));
        $mime->setText(sprintf '#%02x%02x%02x',
                      this->{color}->red(),
                      this->{color}->green(),
                      this->{color}->blue());

        my $pixmap = Qt::Pixmap(34, 34);
        $pixmap->fill(Qt::Color(Qt::white()));

        my $painter = Qt::Painter($pixmap);
        $painter->translate(15, 15);
        $painter->setRenderHint(Qt::Painter::Antialiasing());
        this->paint($painter, 0, 0);
        $painter->end();

        $pixmap->setMask($pixmap->createHeuristicMask());

        $drag->setPixmap($pixmap);
        $drag->setHotSpot(Qt::Point(15, 20));
    }

    $drag->exec();
    this->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
}

sub mouseReleaseEvent
{
    this->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
}

1;
