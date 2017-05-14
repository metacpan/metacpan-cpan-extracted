package SourceWidget;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

#[0]
use QtCore4::slots
    createData => ['QString'],
    startDrag => [];
#[0]

use MimeData;

sub NEW {
    shift->SUPER::NEW();
    my $imageFile = Qt::File('images/example.svg');
    $imageFile->open(Qt::IODevice::ReadOnly());
    my $imageData = $imageFile->readAll();
    this->{imageData} = $imageData;
    $imageFile->close();

    my $imageArea = Qt::ScrollArea();
    my $imageLabel = Qt::SvgWidget();
    this->{imageLabel} = $imageLabel;
    $imageLabel->renderer()->load($imageData);
    $imageArea->setWidget($imageLabel);
    #imageLabel->setMinimumSize(imageLabel->renderer()->viewBox()->size());

    my $instructTopLabel = Qt::Label(this->tr('This is an SVG drawing:'));
    my $instructBottomLabel = Qt::Label(
        this->tr('Drag the icon to copy the drawing as a PNG file:'));
    my $dragIcon = Qt::PushButton(this->tr('Export'));
    $dragIcon->setIcon(Qt::Icon('images/drag.png'));

    this->connect($dragIcon, SIGNAL 'pressed()', this, SLOT 'startDrag()');

    my $layout = Qt::GridLayout();
    $layout->addWidget($instructTopLabel, 0, 0, 1, 2);
    $layout->addWidget($imageArea, 1, 0, 2, 2);
    $layout->addWidget($instructBottomLabel, 3, 0);
    $layout->addWidget($dragIcon, 3, 1);
    this->setLayout($layout);
    this->setWindowTitle(this->tr('Delayed Encoding'));
}

#[1]
sub createData {
    my ($mimeType) = @_;
    if ($mimeType ne 'image/png') {
        return;
    }

    my $imageLabel = this->{imageLabel};
    my $image = Qt::Image($imageLabel->size(), Qt::Image::Format_RGB32());
    my $painter = Qt::Painter();
    $painter->begin($image);
    $imageLabel->renderer()->render($painter);
    $painter->end();

    my $data = Qt::ByteArray();
    my $buffer = Qt::Buffer($data);
    $buffer->open(Qt::IODevice::WriteOnly());
    $image->save($buffer, 'PNG');
    $buffer->close();

    my $mimeData = this->{mimeData};
    $mimeData->setData('image/png', $data);
}
#[1]

#[0]
sub startDrag {
    my $mimeData = MimeData();
    this->{mimeData} = $mimeData;

    this->connect($mimeData, SIGNAL 'dataRequested(QString)',
            this, SLOT 'createData(QString)', Qt::DirectConnection());

    my $drag = Qt::Drag(this);
    $drag->setMimeData($mimeData);
    $drag->setPixmap(Qt::Pixmap('images/drag.png'));

    $drag->exec(Qt::CopyAction());
}
#[0]

1;
