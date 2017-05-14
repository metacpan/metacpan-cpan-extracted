package ScribbleArea;

use strict;
use warnings;

use List::Util qw(max);
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    clearImage => [],
    print => [];

sub isModified() {
    return this->modified;
}

sub penColor() {
    return this->myPenColor;
}

sub penWidth() {
    return this->myPenWidth;
}

sub modified() {
    return this->{modified};
}

sub scribbling() {
    return this->{scribbling};
}

sub myPenWidth() {
    return this->{myPenWidth};
}

sub myPenColor() {
    return this->{myPenColor};
}

sub image() {
    return this->{image};
}

sub lastPoint() {
    return this->{lastPoint};
}
# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setAttribute(Qt::WA_StaticContents());
    this->{modified} = 0;
    this->{scribbling} = 0;
    this->{myPenWidth} = 1;
    this->{myPenColor} = Qt::Color(Qt::blue());
    this->{image} = Qt::Image();
}
# [0]

# [1]
sub openImage {
    my ($fileName) = @_;
# [1] //! [2]
    my $loadedImage = Qt::Image();
    if (!$loadedImage->load($fileName)) {
        return 0;
    }

    my $newSize = $loadedImage->size()->expandedTo(this->size());
    this->resizeImage($loadedImage, $newSize);
    this->{image} = $loadedImage;
    this->{modified} = 0;
    this->update();
    return 1;
}
# [2]

# [3]
sub saveImage {
    my ($fileName, $fileFormat) = @_;
# [3] //! [4]
    my $visibleImage = this->image;
    this->resizeImage($visibleImage, this->size());

    if ($visibleImage->save($fileName, $fileFormat)) {
        this->{modified} = 0;
        return 1;
    } else {
        return 0;
    }
}
# [4]

# [5]
sub setPenColor {
# [5] //! [6]
    my ($newColor) = @_;
    this->{myPenColor} = $newColor;
}
# [6]

# [7]
sub setPenWidth {
# [7] //! [8]
    my ($newWidth) = @_;
    this->{myPenWidth} = $newWidth;
}
# [8]

# [9]
sub clearImage {
# [9] //! [10]
    # This is equivalent of qRgb(255, 255, 255)
    this->image->fill((255 << 16) + (255 << 8) + 255);
    this->{modified} = 1;
    this->update();
}
# [10]

# [11]
sub mousePressEvent {
# [11] //! [12]
    my ($event) = @_;
    if ($event->button() == Qt::LeftButton()) {
        this->{lastPoint} = Qt::Point($event->pos());
        this->{scribbling} = 1;
    }
}

sub mouseMoveEvent {
    my ($event) = @_;
    if (($event->buttons() & ${Qt::LeftButton()}) && this->scribbling) {
        this->drawLineTo($event->pos());
    }
}

sub mouseReleaseEvent {
    my ($event) = @_;
    if ($event->button() == Qt::LeftButton() && this->scribbling) {
        this->drawLineTo($event->pos());
        this->{scribbling} = 0;
    }
}

# [12] //! [13]
sub paintEvent {
# [13] //! [14]
    my $painter = Qt::Painter(this);
    $painter->drawImage(Qt::Point(0, 0), this->image);
    $painter->end();
}
# [14]

# [15]
sub resizeEvent {
    my ($event) = @_;
# [15] //! [16]
    if (this->width() > this->image->width() || this->height() > this->image->height()) {
        my $newWidth = max(this->width() + 128, this->image->width());
        my $newHeight = max(this->height() + 128, this->image->height());
        this->resizeImage(this->image, Qt::Size($newWidth, $newHeight));
        this->update();
    }
    this->SUPER::resizeEvent($event);
}
# [16]

# [17]
sub drawLineTo {
# [17] //! [18]
    my ($endPoint) = @_;
    my $painter = Qt::Painter(this->image);
    $painter->setPen(Qt::Pen(Qt::Brush(this->myPenColor), this->myPenWidth, 
        Qt::SolidLine(), Qt::RoundCap(), Qt::RoundJoin()));
    $painter->drawLine(this->lastPoint, $endPoint);
    this->{modified} = 1;

    my $rad = (this->myPenWidth / 2) + 2;
    this->update(Qt::Rect(this->lastPoint, $endPoint)->normalized()->adjusted(
                                     -$rad, -$rad, +$rad, +$rad));
    this->{lastPoint} = Qt::Point($endPoint);
    $painter->end();
}
# [18]

# [19]
sub resizeImage {
# [19] //! [20]
    my ($image, $newSize) = @_;
    if ($image->size() == $newSize) {
        return;
    }

    my $newImage = Qt::Image($newSize, Qt::Image::Format_RGB32());
    # This is equivalent of qRgb(255, 255, 255)
    $newImage->fill((255 << 16) + (255 << 8) + 255);
    my $painter = Qt::Painter($newImage);
    $painter->drawImage(Qt::Point(0, 0), $image);
    this->{image} = $newImage;
    $painter->end();
}
# [20]

# [21]
sub print {
#ifndef QT_NO_PRINTER
    my $printer = Qt::Printer(Qt::Printer::HighResolution());
 
    my $printDialog = Qt::PrintDialog($printer, this);
# [21] //! [22]
    if ($printDialog->exec() == Qt::Dialog::Accepted()) {
        my $painter = Qt::Painter($printer);
        my $rect = $painter->viewport();
        my $size = this->image->size();
        $size->scale($rect->size(), Qt::KeepAspectRatio());
        $painter->setViewport($rect->x(), $rect->y(), $size->width(), $size->height());
        $painter->setWindow(this->image->rect());
        $painter->drawImage(0, 0, this->image);
    }
#endif // Qt::T_NO_PRINTER
}
# [22]

1;
