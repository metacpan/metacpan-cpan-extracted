package MainWindow;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
# [0]
use QtCore4::slots
    brushColorAct => [],
    alphaActionTriggered => ['QAction*'],
    lineWidthActionTriggered => ['QAction*'],
    saturationActionTriggered => ['QAction*'],
    saveAct => [],
    loadAct => [],
    aboutAct => [];

use TabletCanvas;

sub myCanvas() {
    return this->{myCanvas};
}

sub brushColorAction() {
    return this->{brushColorAction};
}

sub brushActionGroup() {
    return this->{brushActionGroup};
}

sub alphaChannelGroup() {
    return this->{alphaChannelGroup};
}

sub alphaChannelPressureAction() {
    return this->{alphaChannelPressureAction};
}

sub alphaChannelTiltAction() {
    return this->{alphaChannelTiltAction};
}

sub noAlphaChannelAction() {
    return this->{noAlphaChannelAction};
}

sub colorSaturationGroup() {
    return this->{colorSaturationGroup};
}

sub colorSaturationVTiltAction() {
    return this->{colorSaturationVTiltAction};
}

sub colorSaturationHTiltAction() {
    return this->{colorSaturationHTiltAction};
}

sub colorSaturationPressureAction() {
    return this->{colorSaturationPressureAction};
}

sub noColorSaturationAction() {
    return this->{noColorSaturationAction};
}

sub lineWidthGroup() {
    return this->{lineWidthGroup};
}

sub lineWidthPressureAction() {
    return this->{lineWidthPressureAction};
}

sub lineWidthTiltAction() {
    return this->{lineWidthTiltAction};
}

sub lineWidthFixedAction() {
    return this->{lineWidthFixedAction};
}

sub exitAction() {
    return this->{exitAction};
}

sub saveAction() {
    return this->{saveAction};
}

sub loadAction() {
    return this->{loadAction};
}

sub aboutAction() {
    return this->{aboutAction};
}

sub aboutQtAction() {
    return this->{aboutQtAction};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub brushMenu() {
    return this->{brushMenu};
}

sub tabletMenu() {
    return this->{tabletMenu};
}

sub helpMenu() {
    return this->{helpMenu};
}

sub colorSaturationMenu() {
    return this->{colorSaturationMenu};
}

sub lineWidthMenu() {
    return this->{lineWidthMenu};
}

sub alphaChannelMenu() {
    return this->{alphaChannelMenu};
}
# [0]

# [0]
sub NEW {
    my ($class, $canvas) = @_;
    $class->SUPER::NEW();
    this->{myCanvas} = $canvas;
    this->createActions();
    this->createMenus();

    this->myCanvas->setColor(Qt::red());
    this->myCanvas->setLineWidthType(TabletCanvas::LineWidthPressure());
    this->myCanvas->setAlphaChannelType(TabletCanvas::NoAlpha());
    this->myCanvas->setColorSaturationType(TabletCanvas::NoSaturation());

    this->setWindowTitle(this->tr('Tablet Example'));
    this->setCentralWidget(this->myCanvas);
}
# [0]

# [1]
sub brushColorAct {
    my $color = Qt::ColorDialog::getColor(this->myCanvas->color());

    if ($color->isValid()) {
        this->myCanvas->setColor($color);
    }
}
# [1]

# [2]
sub alphaActionTriggered {
    my ($action) = @_;
    if ($action == this->alphaChannelPressureAction) {
        this->myCanvas->setAlphaChannelType(TabletCanvas::AlphaPressure());
    } elsif ($action == this->alphaChannelTiltAction) {
        this->myCanvas->setAlphaChannelType(TabletCanvas::AlphaTilt());
    } else {
        this->myCanvas->setAlphaChannelType(TabletCanvas::NoAlpha());
    }
}
# [2]

# [3]
sub lineWidthActionTriggered {
    my ($action) = @_;
    if ($action == this->lineWidthPressureAction) {
        this->myCanvas->setLineWidthType(TabletCanvas::LineWidthPressure());
    } elsif ($action == this->lineWidthTiltAction) {
        this->myCanvas->setLineWidthType(TabletCanvas::LineWidthTilt());
    } else {
        this->myCanvas->setLineWidthType(TabletCanvas::NoLineWidth());
    }
}
# [3]

# [4]
sub saturationActionTriggered {
    my ($action) = @_;
    if ($action == this->colorSaturationVTiltAction) {
        this->myCanvas->setColorSaturationType(TabletCanvas::SaturationVTilt());
    } elsif ($action == this->colorSaturationHTiltAction) {
        this->myCanvas->setColorSaturationType(TabletCanvas::SaturationHTilt());
    } elsif ($action == this->colorSaturationPressureAction) {
        this->myCanvas->setColorSaturationType(TabletCanvas::SaturationPressure());
    } else {
        this->myCanvas->setColorSaturationType(TabletCanvas::NoSaturation());
    }
}
# [4]

# [5]
sub saveAct {
    my $path = Qt::Dir::currentPath() . '/untitled.png';
    my $fileName = Qt::FileDialog::getSaveFileName(this, this->tr('Save Picture'),
                             $path);

    if (!this->myCanvas->saveImage($fileName)) {
        Qt::MessageBox::information(this, 'Error Saving Picture',
                                 'Could not save the image');
    }
}
# [5]

# [6]
sub loadAct {
    my $fileName = Qt::FileDialog::getOpenFileName(this, this->tr('Open Picture'),
                                                    Qt::Dir::currentPath());

    if (!this->myCanvas->loadImage($fileName)) {
        Qt::MessageBox::information(this, 'Error Opening Picture',
                                 'Could not open picture');
    }
}
# [6]

# [7]
sub aboutAct {
    Qt::MessageBox::about(this, this->tr('About Tablet Example'),
                       this->tr('This example shows use of a Wacom tablet in Qt4'));
}
# [7]

# [8]
sub createActions {
# [8]
    this->{brushColorAction} = Qt::Action(this->tr('&Brush Color...'), this);
    this->brushColorAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+C')));
    this->connect(this->brushColorAction, SIGNAL 'triggered()',
            this, SLOT 'brushColorAct()');

# [9]
    this->{alphaChannelPressureAction} = Qt::Action(this->tr('&Pressure'), this);
    this->alphaChannelPressureAction->setCheckable(1);

    this->{alphaChannelTiltAction} = Qt::Action(this->tr('&Tilt'), this);
    this->alphaChannelTiltAction->setCheckable(1);

    this->{noAlphaChannelAction} = Qt::Action(this->tr('No Alpha Channel'), this);
    this->noAlphaChannelAction->setCheckable(1);
    this->noAlphaChannelAction->setChecked(1);

    this->{alphaChannelGroup} = Qt::ActionGroup(this);
    this->alphaChannelGroup->addAction(this->alphaChannelPressureAction);
    this->alphaChannelGroup->addAction(this->alphaChannelTiltAction);
    this->alphaChannelGroup->addAction(this->noAlphaChannelAction);
    this->connect(this->alphaChannelGroup, SIGNAL 'triggered(QAction *)',
            this, SLOT 'alphaActionTriggered(QAction *)');

# [9]
    this->{colorSaturationVTiltAction} = Qt::Action(this->tr('&Vertical Tilt'), this);
    this->colorSaturationVTiltAction->setCheckable(1);

    this->{colorSaturationHTiltAction} = Qt::Action(this->tr('&Horizontal Tilt'), this);
    this->colorSaturationHTiltAction->setCheckable(1);

    this->{colorSaturationPressureAction} = Qt::Action(this->tr('&Pressure'), this);
    this->colorSaturationPressureAction->setCheckable(1);

    this->{noColorSaturationAction} = Qt::Action(this->tr('&No Color Saturation'), this);
    this->noColorSaturationAction->setCheckable(1);
    this->noColorSaturationAction->setChecked(1);

    this->{colorSaturationGroup} = Qt::ActionGroup(this);
    this->colorSaturationGroup->addAction(this->colorSaturationVTiltAction);
    this->colorSaturationGroup->addAction(this->colorSaturationHTiltAction);
    this->colorSaturationGroup->addAction(this->colorSaturationPressureAction);
    this->colorSaturationGroup->addAction(this->noColorSaturationAction);
    this->connect(this->colorSaturationGroup, SIGNAL 'triggered(QAction *)',
            this, SLOT 'saturationActionTriggered(QAction *)');

    this->{lineWidthPressureAction} = Qt::Action(this->tr('&Pressure'), this);
    this->lineWidthPressureAction->setCheckable(1);
    this->lineWidthPressureAction->setChecked(1);

    this->{lineWidthTiltAction} = Qt::Action(this->tr('&Tilt'), this);
    this->lineWidthTiltAction->setCheckable(1);

    this->{lineWidthFixedAction} = Qt::Action(this->tr('&Fixed'), this);
    this->lineWidthFixedAction->setCheckable(1);

    this->{lineWidthGroup} = Qt::ActionGroup(this);
    this->lineWidthGroup->addAction(this->lineWidthPressureAction);
    this->lineWidthGroup->addAction(this->lineWidthTiltAction);
    this->lineWidthGroup->addAction(this->lineWidthFixedAction);
    this->connect(this->lineWidthGroup, SIGNAL 'triggered(QAction *)',
            this, SLOT 'lineWidthActionTriggered(QAction *)');

    this->{exitAction} = Qt::Action(this->tr('E&xit'), this);
    this->exitAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+X')));
    this->connect(this->exitAction, SIGNAL 'triggered()',
            this, SLOT 'close()');

    this->{loadAction} = Qt::Action(this->tr('&Open...'), this);
    this->loadAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+O')));
    this->connect(this->loadAction, SIGNAL 'triggered()',
            this, SLOT 'loadAct()');

    this->{saveAction} = Qt::Action(this->tr('&Save As...'), this);
    this->saveAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+S')));
    this->connect(this->saveAction, SIGNAL 'triggered()',
            this, SLOT 'saveAct()');

    this->{aboutAction} = Qt::Action(this->tr('A&bout'), this);
    this->aboutAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+B')));
    this->connect(this->aboutAction, SIGNAL 'triggered()',
            this, SLOT 'aboutAct()');

    this->{aboutQtAction} = Qt::Action(this->tr('About &Qt'), this);
    this->aboutQtAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+Q')));
    this->connect(this->aboutQtAction, SIGNAL 'triggered()',
            qApp, SLOT 'aboutQt()');
# [10]
}
# [10]

# [11]
sub createMenus {
    this->{fileMenu} = this->menuBar()->addMenu(this->tr('&File'));
    fileMenu->addAction(this->loadAction);
    fileMenu->addAction(this->saveAction);
    fileMenu->addSeparator();
    fileMenu->addAction(this->exitAction);

    this->{brushMenu} = this->menuBar()->addMenu(this->tr('&Brush'));
    this->brushMenu->addAction(this->brushColorAction);

    this->{tabletMenu} = this->menuBar()->addMenu(this->tr('&Tablet'));

    this->{lineWidthMenu} = this->tabletMenu->addMenu(this->tr('&Line Width'));
    this->lineWidthMenu->addAction(this->lineWidthPressureAction);
    this->lineWidthMenu->addAction(this->lineWidthTiltAction);
    this->lineWidthMenu->addAction(this->lineWidthFixedAction);

    this->{alphaChannelMenu} = this->tabletMenu->addMenu(this->tr('&Alpha Channel'));
    this->alphaChannelMenu->addAction(this->alphaChannelPressureAction);
    this->alphaChannelMenu->addAction(this->alphaChannelTiltAction);
    this->alphaChannelMenu->addAction(this->noAlphaChannelAction);

    this->{colorSaturationMenu} = this->tabletMenu->addMenu(this->tr('&Color Saturation'));
    this->colorSaturationMenu->addAction(this->colorSaturationVTiltAction);
    this->colorSaturationMenu->addAction(this->colorSaturationHTiltAction);
    this->colorSaturationMenu->addAction(this->noColorSaturationAction);

    this->{helpMenu} = this->menuBar()->addMenu('&Help');
    this->helpMenu->addAction(this->aboutAction);
    this->helpMenu->addAction(this->aboutQtAction);
}
# [11]

1;
