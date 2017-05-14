package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use GLWidget;

sub glWidget() {
    return this->{glWidget};
}

sub xSlider() {
    return this->{xSlider};
}

sub ySlider() {
    return this->{ySlider};
}

sub zSlider() {
    return this->{zSlider};
}

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    Qt::setSignature( 'QGLWidget::QGLWidget( QWidget* )' );
    this->{glWidget} = GLWidget();

    this->{xSlider} = this->createSlider();
    this->{ySlider} = this->createSlider();
    this->{zSlider} = this->createSlider();

    this->connect(this->xSlider, SIGNAL 'valueChanged(int)', this->glWidget, SLOT 'setXRotation(int)');
    this->connect(this->glWidget, SIGNAL 'xRotationChanged(int)', this->xSlider, SLOT 'setValue(int)');
    this->connect(this->ySlider, SIGNAL 'valueChanged(int)', this->glWidget, SLOT 'setYRotation(int)');
    this->connect(this->glWidget, SIGNAL 'yRotationChanged(int)', this->ySlider, SLOT 'setValue(int)');
    this->connect(this->zSlider, SIGNAL 'valueChanged(int)', this->glWidget, SLOT 'setZRotation(int)');
    this->connect(this->glWidget, SIGNAL 'zRotationChanged(int)', this->zSlider, SLOT 'setValue(int)');
# [0]

# [1]
    my $mainLayout = Qt::HBoxLayout();
    $mainLayout->addWidget(this->glWidget);
    $mainLayout->addWidget(this->xSlider);
    $mainLayout->addWidget(this->ySlider);
    $mainLayout->addWidget(this->zSlider);
    this->setLayout($mainLayout);

    this->xSlider->setValue(15 * 16);
    this->ySlider->setValue(345 * 16);
    this->zSlider->setValue(0 * 16);
    this->setWindowTitle(this->tr('Hello GL'));
}
# [1]

# [2]
sub createSlider
{
    my $slider = Qt::Slider(Qt::Vertical());
    $slider->setRange(0, 360 * 16);
    $slider->setSingleStep(16);
    $slider->setPageStep(15 * 16);
    $slider->setTickInterval(15 * 16);
    $slider->setTickPosition(Qt::Slider::TicksRight());
    return $slider;
}
# [2]

1;
