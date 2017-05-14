package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use BorderLayout;

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    my $centralWidget = Qt::TextBrowser();
    $centralWidget->setPlainText(this->tr('Central widget'));

    my $layout = BorderLayout();
    $layout->addWidget($centralWidget, BorderLayout::Center);
    $layout->addWidget(this->createLabel('North'), BorderLayout::North);
    $layout->addWidget(this->createLabel('West'), BorderLayout::West);
    $layout->addWidget(this->createLabel('East 1'), BorderLayout::East);
    $layout->addWidget(this->createLabel('East 2') , BorderLayout::East);
    $layout->addWidget(this->createLabel('South'), BorderLayout::South);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('Border Layout'));
}

sub createLabel
{
    my ($text) = @_;
    my $label = Qt::Label($text);
    $label->setFrameStyle(Qt::Frame::Box() | Qt::Frame::Raised());
    return $label;
}

1;
