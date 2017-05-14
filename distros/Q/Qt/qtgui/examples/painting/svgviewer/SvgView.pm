package SvgView;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtSvg4;
use QtCore4::isa qw( Qt::GraphicsView );
use QtCore4::slots
    setHighQualityAntialiasing => ['bool'],
    setViewBackground => ['bool'],
    setViewOutline => ['bool'];

use constant {
    Native => 0,
    OpenGL => 1,
    Image => 2
};

sub m_renderer() {
    return this->{m_renderer};
}

sub m_svgItem() {
    return this->{m_svgItem};
}

sub m_backgroundItem() {
    return this->{m_backgroundItem};
}

sub m_outlineItem() {
    return this->{m_outlineItem};
}

sub m_image() {
    return this->{m_image};
}

sub NEW
{
    my ($class, $parent) = @_;
    if ( $parent ) {
        $class->SUPER::NEW($parent);
    }
    else {
        $class->SUPER::NEW();
    }
    this->{m_renderer} = Native;
    this->{svgItem} = 0;
    this->{backgroundItem} = 0;
    this->{outlineItem} = 0;
    this->{m_image} = Qt::Image();

    this->setScene(Qt::GraphicsScene(this));
    this->setTransformationAnchor(Qt::GraphicsView::AnchorUnderMouse());
    this->setDragMode(Qt::GraphicsView::ScrollHandDrag());

    # Prepare background check-board pattern
    my $tilePixmap = Qt::Pixmap(64, 64);
    $tilePixmap->fill(Qt::Color(Qt::white()));
    my $tilePainter = Qt::Painter($tilePixmap);
    my $color = Qt::Color(220, 220, 220);
    $tilePainter->fillRect(0, 0, 32, 32, Qt::Brush($color));
    $tilePainter->fillRect(32, 32, 32, 32, Qt::Brush($color));
    $tilePainter->end();

    this->setBackgroundBrush(Qt::Brush($tilePixmap));
}

sub drawBackground
{
    my ($p) = @_;
    $p->save();
    $p->resetTransform();
    $p->drawTiledPixmap(this->viewport()->rect(), this->backgroundBrush()->texture());
    $p->restore();
}

sub openFile
{
    my ($file) = @_;
    if (!$file->exists()) {
        return;
    }

    my $s = this->scene();

    my $drawBackground = (this->m_backgroundItem ? this->m_backgroundItem->isVisible() : 0);
    my $drawOutline = (this->m_outlineItem ? this->m_outlineItem->isVisible() : 1);

    $s->clear();
    this->resetTransform();

    this->{m_svgItem} = Qt::GraphicsSvgItem($file->fileName());
    this->m_svgItem->setFlags(Qt::GraphicsItem::ItemClipsToShape());
    this->m_svgItem->setCacheMode(Qt::GraphicsItem::NoCache());
    this->m_svgItem->setZValue(0);

    this->{m_backgroundItem} = Qt::GraphicsRectItem(this->m_svgItem->boundingRect());
    this->m_backgroundItem->setBrush(Qt::Brush(Qt::white()));
    this->m_backgroundItem->setPen(Qt::Pen(Qt::NoPen()));
    this->m_backgroundItem->setVisible($drawBackground);
    this->m_backgroundItem->setZValue(-1);

    this->{m_outlineItem} = Qt::GraphicsRectItem(this->m_svgItem->boundingRect());
    my $outline = Qt::Pen(Qt::Brush(Qt::black()), 2, Qt::DashLine());
    $outline->setCosmetic(1);
    this->m_outlineItem->setPen($outline);
    # FIXME This should work with the 1 argument form.  But that has been cached
    # already as calling the QBrush(Qt::GlobalColor) constructor.
    this->m_outlineItem->setBrush(Qt::Brush(Qt::white(), Qt::NoBrush()));
    this->m_outlineItem->setVisible($drawOutline);
    this->m_outlineItem->setZValue(1);

    $s->addItem(this->m_backgroundItem);
    $s->addItem(this->m_svgItem);
    $s->addItem(this->m_outlineItem);

    $s->setSceneRect(this->m_outlineItem->boundingRect()->adjusted(-10, -10, 10, 10));
}

sub setRenderer
{
    my ($type) = @_;
    this->{m_renderer} = $type;

    if (this->m_renderer == OpenGL) {
#ifndef QT_NO_OPENGL
        this->setViewport(Qt::GLWidget(Qt::GLFormat(Qt::GL::SampleBuffers())));
#endif
    } else {
        this->setViewport(Qt::Widget());
    }
}

sub setHighQualityAntialiasing
{
    my ($highQualityAntialiasing) = @_;
#ifndef QT_NO_OPENGL
    this->setRenderHint(Qt::Painter::HighQualityAntialiasing(), $highQualityAntialiasing);
#endif
}

sub setViewBackground
{
    my ($enable) = @_;
    if (!this->m_backgroundItem) {
          return;
    }

    this->m_backgroundItem->setVisible($enable);
}

sub setViewOutline
{
    my ($enable) = @_;
    if (!this->m_outlineItem) {
        return;
    }

    this->m_outlineItem->setVisible($enable);
}

sub paintEvent
{
    my ($event) = @_;
    if (this->m_renderer == Image) {
        if (this->m_image->size() != this->viewport()->size()) {
            this->{m_image} = Qt::Image(this->viewport()->size(), Qt::Image::Format_ARGB32_Premultiplied());
        }

        my $imagePainter = Qt::Painter(this->m_image);
        this->SUPER::render($imagePainter);
        $imagePainter->end();

        my $p = Qt::Painter(this->viewport());
        $p->drawImage(0, 0, this->m_image);
        $p->end();

    } else {
        this->SUPER::paintEvent($event);
    }
}

sub wheelEvent
{
    my ($event) = @_;
    my $factor = 1.2 ** ($event->delta() / 240.0);
    this->scale($factor, $factor);
    $event->accept();
}

1;
