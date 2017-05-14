package MainWindow;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );

sub centralWidget() {
    return this->{centralWidget};
}

sub label() {
    return this->{label};
}

sub groupBox() {
    return this->{groupBox};
}

sub listWidget() {
    return this->{listWidget};
}

sub perspectiveRadioButton() {
    return this->{perspectiveRadioButton};
}

sub isometricRadioButton() {
    return this->{isometricRadioButton};
}

sub obliqueRadioButton() {
    return this->{obliqueRadioButton};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub exitAction() {
    return this->{exitAction};
}

my $listEntries = [
    ['MainWindow', 'First'],
    ['MainWindow', 'Second'],
    ['MainWindow', 'Third'],
    0
];

sub NEW {
    my ( $class ) = @_;
    $class->SUPER::NEW();
    my $centralWidget = Qt::Widget();
    this->{centralWidget} = $centralWidget;
    this->setCentralWidget($centralWidget);

    this->createGroupBox();

    my $listWidget = Qt::ListWidget();
    this->{listWidget} = $listWidget;
    for (my $i = 0; $listEntries->[$i]; ++$i) {
        $listWidget->addItem(qApp->translate($listEntries->[$i]->[0], $listEntries->[$i]->[1]));
    }

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget(this->groupBox);
    $mainLayout->addWidget($listWidget);
    $centralWidget->setLayout($mainLayout);

    my $exitAction = Qt::Action(this->tr('E&xit'), this);
    this->{exitAction} = $exitAction;
    this->connect($exitAction, SIGNAL 'triggered()', qApp, SLOT 'quit()');

    my $fileMenu = this->menuBar()->addMenu(this->tr('&File'));
    this->{fileMenu} = $fileMenu;
    $fileMenu->setPalette(Qt::Palette(Qt::red()));
    $fileMenu->addAction($exitAction);

    this->setWindowTitle(this->tr('Language:').this->tr('English'));
    this->statusBar()->showMessage(this->tr('Internationalization Example'));

    if (this->tr('LTR') eq 'RTL') {
        this->setLayoutDirection(Qt::RightToLeft());
    }
}

sub createGroupBox {
    my $groupBox = Qt::GroupBox(this->tr('View'));
    this->{groupBox} = $groupBox;
    my $perspectiveRadioButton = Qt::RadioButton(this->tr('Perspective'));
    this->{perspectiveRadioButton} = $perspectiveRadioButton;
    my $isometricRadioButton = Qt::RadioButton(this->tr('Isometric'));
    this->{isometricRadioButton} = $isometricRadioButton;
    my $obliqueRadioButton = Qt::RadioButton(this->tr('Oblique'));
    this->{obliqueRadioButton} = $obliqueRadioButton;
    $perspectiveRadioButton->setChecked(1);

    my $groupBoxLayout = Qt::VBoxLayout();
    $groupBoxLayout->addWidget($perspectiveRadioButton);
    $groupBoxLayout->addWidget($isometricRadioButton);
    $groupBoxLayout->addWidget($obliqueRadioButton);
    $groupBox->setLayout($groupBoxLayout);
}

1;
