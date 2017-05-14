package Window;

# use blib;
use Qt;
use Qt::QString;
use Qt::QWidget;
use Qt::QCheckBox;
use Qt::QComboBox;
use Qt::QGroupBox;
use Qt::QLabel;
use Qt::QSpinBox;
use Qt::QStackedWidget;
use Qt::QGridLayout;
use Qt::QBoxLayout;

use SlidersGroup;

our @ISA = qw(Qt::QWidget);
our @EXPORT = qw(Window);


sub Window {
    my $class = 'Window';
    my $this = QWidget();
    bless $this, $class;

    $this->{horizontalSliders} = SlidersGroup(Qt::Horizontal, QString("Horizontal"));
    $this->{verticalSliders} = SlidersGroup(Qt::Vertical, QString("Vertical"));

    $this->{stackedWidget} = QStackedWidget();
    $this->{stackedWidget}->addWidget($this->{horizontalSliders});
    $this->{stackedWidget}->addWidget($this->{verticalSliders});

    $this->createControls(QString("Controls"));

    $this->connect($this->{horizontalSliders}, SIGNAL('valueChanged(int)'), $this->{verticalSliders}, SLOT('setValue(int)'));
    $this->connect($this->{verticalSliders}, SIGNAL('valueChanged(int)'), $this->{valueSpinBox}, SLOT('setValue(int)'));
    $this->connect($this->{valueSpinBox}, SIGNAL('valueChanged(int)'), $this->{horizontalSliders}, SLOT('setValue(int)'));

    $this->{layout} = QHBoxLayout();
    $this->{layout}->addWidget($this->{controlsGroup});
    $this->{layout}->addWidget($this->{stackedWidget});
    $this->setLayout($this->{layout});

    $this->{minimumSpinBox}->setValue(0);
    $this->{maximumSpinBox}->setValue(20);
    $this->{valueSpinBox}->setValue(5);

    $this->setWindowTitle(QString('Sliders'));

    return $this;
}


sub createControls {
    my $this = shift;
    my $title = shift;
    $this->{controlsGroup} = QGroupBox($title);

    $this->{minimumLabel} = QLabel(QString('Minimum value:'));
    $this->{maximumLabel} = QLabel(QString('Maximum value:'));
    $this->{valueLabel} = QLabel(QString('Current value:'));

    $this->{invertedAppearance} = QCheckBox(QString('Inverted appearance'));
    $this->{invertedKeyBindings} = QCheckBox(QString('Inverted key bindings'));

    $this->{minimumSpinBox} = QSpinBox();
    $this->{minimumSpinBox}->setRange(-100, 100);
    $this->{minimumSpinBox}->setSingleStep(1);

    $this->{maximumSpinBox} = QSpinBox();
    $this->{maximumSpinBox}->setRange(-100, 100);
    $this->{maximumSpinBox}->setSingleStep(1);
    
    $this->{valueSpinBox} = QSpinBox();
    $this->{valueSpinBox}->setRange(-100, 100);
    $this->{valueSpinBox}->setSingleStep(1);

    $this->{orientationCombo} = QComboBox();
    $this->{orientationCombo}->addItem(QString("Horizontal slider-like widgets"));
    $this->{orientationCombo}->addItem(QString("Vertical slider-like widgets"));

    $this->connect($this->{orientationCombo}, SIGNAL('activated(int)'), $this->{stackedWidget}, SLOT('setCurrentIndex(int)'));
    $this->connect($this->{minimumSpinBox}, SIGNAL('valueChanged(int)'), $this->{horizontalSliders}, SLOT('setMinimum(int)'));
    $this->connect($this->{minimumSpinBox}, SIGNAL('valueChanged(int)'), $this->{verticalSliders}, SLOT('setMinimum(int)'));
    $this->connect($this->{maximumSpinBox}, SIGNAL('valueChanged(int)'), $this->{horizontalSliders}, SLOT('setMaximum(int)'));
    $this->connect($this->{maximumSpinBox}, SIGNAL('valueChanged(int)'), $this->{verticalSliders}, SLOT('setMaximum(int)'));
    $this->connect($this->{invertedAppearance}, SIGNAL('toggled(bool)'), $this->{horizontalSliders}, SLOT('invertAppearance(bool)'));
    $this->connect($this->{invertedAppearance}, SIGNAL('toggled(bool)'), $this->{verticalSliders}, SLOT('invertAppearance(bool)'));
    $this->connect($this->{invertedKeyBindings}, SIGNAL('toggled(bool)'), $this->{horizontalSliders}, SLOT('invertKeyBindings(bool)'));
    $this->connect($this->{invertedKeyBindings}, SIGNAL('toggled(bool)'), $this->{verticalSliders}, SLOT('invertKeyBindings(bool)'));

    $this->{controlsLayout} = QGridLayout();
    $this->{controlsLayout}->addWidget($this->{minimumLabel}, 0, 0);
    $this->{controlsLayout}->addWidget($this->{maximumLabel}, 1, 0);
    $this->{controlsLayout}->addWidget($this->{valueLabel}, 2, 0);
    $this->{controlsLayout}->addWidget($this->{minimumSpinBox}, 0, 1);
    $this->{controlsLayout}->addWidget($this->{maximumSpinBox}, 1, 1);
    $this->{controlsLayout}->addWidget($this->{valueSpinBox}, 2, 1);
    $this->{controlsLayout}->addWidget($this->{invertedAppearance}, 0, 2);
    $this->{controlsLayout}->addWidget($this->{invertedKeyBindings}, 1, 2);
    $this->{controlsLayout}->addWidget($this->{orientationCombo}, 3, 0, 1, 3);
    $this->{controlsGroup}->setLayout($this->{controlsLayout});
}

1;

