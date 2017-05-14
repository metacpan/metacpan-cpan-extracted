package ControllerWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use PreviewWindow;

# FIXME
use constant {
    Window=>0x00000001
};

use constant {
    Dialog=>0x00000002 | Window,
    SplashScreen=>0x0000000e | Window,
    ToolTip=>0x0000000c | Window
};

# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    updatePreview => [];

sub previewWindow() {
    return this->{previewWindow};
}


sub typeGroupBox() {
    return this->{typeGroupBox};
}

sub hintsGroupBox() {
    return this->{hintsGroupBox};
}

sub quitButton() {
    return this->{quitButton};
}


sub windowRadioButton() {
    return this->{windowRadioButton};
}

sub dialogRadioButton() {
    return this->{dialogRadioButton};
}

sub sheetRadioButton() {
    return this->{sheetRadioButton};
}

sub drawerRadioButton() {
    return this->{drawerRadioButton};
}

sub popupRadioButton() {
    return this->{popupRadioButton};
}

sub toolRadioButton() {
    return this->{toolRadioButton};
}

sub toolTipRadioButton() {
    return this->{toolTipRadioButton};
}

sub splashScreenRadioButton() {
    return this->{splashScreenRadioButton};
}


sub msWindowsFixedSizeDialogCheckBox() {
    return this->{msWindowsFixedSizeDialogCheckBox};
}

sub x11BypassWindowManagerCheckBox() {
    return this->{x11BypassWindowManagerCheckBox};
}

sub framelessWindowCheckBox() {
    return this->{framelessWindowCheckBox};
}

sub windowTitleCheckBox() {
    return this->{windowTitleCheckBox};
}

sub windowSystemMenuCheckBox() {
    return this->{windowSystemMenuCheckBox};
}

sub windowMinimizeButtonCheckBox() {
    return this->{windowMinimizeButtonCheckBox};
}

sub windowMaximizeButtonCheckBox() {
    return this->{windowMaximizeButtonCheckBox};
}

sub windowCloseButtonCheckBox() {
    return this->{windowCloseButtonCheckBox};
}

sub windowContextHelpButtonCheckBox() {
    return this->{windowContextHelpButtonCheckBox};
}

sub windowShadeButtonCheckBox() {
    return this->{windowShadeButtonCheckBox};
}

sub windowStaysOnTopCheckBox() {
    return this->{windowStaysOnTopCheckBox};
}

sub windowStaysOnBottomCheckBox() {
    return this->{windowStaysOnBottomCheckBox};
}

sub customizeWindowHintCheckBox() {
    return this->{customizeWindowHintCheckBox};
}
# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->{previewWindow} = PreviewWindow(this);

    this->createTypeGroupBox();
    this->createHintsGroupBox();

    my $quitButton = this->{quitButton} = Qt::PushButton(this->tr('&Quit'));
    this->connect($quitButton, SIGNAL 'clicked()', qApp, SLOT 'quit()');

    my $bottomLayout = Qt::HBoxLayout();
    $bottomLayout->addStretch();
    $bottomLayout->addWidget($quitButton);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget(this->typeGroupBox);
    $mainLayout->addWidget(this->hintsGroupBox);
    $mainLayout->addLayout($bottomLayout);
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr('Window Flags'));
    this->updatePreview();
}
# [0]

# [1]
sub updatePreview {
    my $flags = 0;

    if (this->windowRadioButton->isChecked()) {
        $flags = Qt::Window();
    } elsif (this->dialogRadioButton->isChecked()) {
        $flags = Dialog;
    } elsif (this->sheetRadioButton->isChecked()) {
        $flags = Qt::Sheet();
    } elsif (this->drawerRadioButton->isChecked()) {
        $flags = Qt::Drawer();
    } elsif (this->popupRadioButton->isChecked()) {
        $flags = Qt::Popup();
    } elsif (this->toolRadioButton->isChecked()) {
        $flags = Qt::Tool();
    } elsif (this->toolTipRadioButton->isChecked()) {
        $flags = ToolTip;
    } elsif (this->splashScreenRadioButton->isChecked()) {
        $flags = SplashScreen;
# [1] //! [2]
    }
# [2] //! [3]

    if (msWindowsFixedSizeDialogCheckBox->isChecked()) {
        $flags |= Qt::MSWindowsFixedSizeDialogHint();
    }
    if (x11BypassWindowManagerCheckBox->isChecked()) {
        $flags |= Qt::X11BypassWindowManagerHint();
    }
    if (framelessWindowCheckBox->isChecked()) {
        $flags |= Qt::FramelessWindowHint();
    }
    if (windowTitleCheckBox->isChecked()) {
        $flags |= Qt::WindowTitleHint();
    }
    if (windowSystemMenuCheckBox->isChecked()) {
        $flags |= Qt::WindowSystemMenuHint();
    }
    if (windowMinimizeButtonCheckBox->isChecked()) {
        $flags |= Qt::WindowMinimizeButtonHint();
    }
    if (windowMaximizeButtonCheckBox->isChecked()) {
        $flags |= Qt::WindowMaximizeButtonHint();
    }
    if (windowCloseButtonCheckBox->isChecked()) {
        $flags |= Qt::WindowCloseButtonHint();
    }
    if (windowContextHelpButtonCheckBox->isChecked()) {
        $flags |= Qt::WindowContextHelpButtonHint();
    }
    if (windowShadeButtonCheckBox->isChecked()) {
        $flags |= Qt::WindowShadeButtonHint();
    }
    if (windowStaysOnTopCheckBox->isChecked()) {
        $flags |= Qt::WindowStaysOnTopHint();
    }
    if (windowStaysOnBottomCheckBox->isChecked()) {
        $flags |= Qt::WindowStaysOnBottomHint();
    }
    if (customizeWindowHintCheckBox->isChecked()) {
        $flags |= Qt::CustomizeWindowHint();
    }

    this->previewWindow->setWindowFlags($flags);
# [3] //! [4]

    my $pos = this->previewWindow->pos();
    if ($pos->x() < 0) {
        $pos->setX(0);
    }
    if ($pos->y() < 0) {
        $pos->setY(0);
    }
    this->previewWindow->move($pos);
    this->previewWindow->show();
}
# [4]

# [5]
sub createTypeGroupBox {
    this->{typeGroupBox} = Qt::GroupBox(this->tr('Type'));

    this->{windowRadioButton} = createRadioButton(this->tr('Window'));
    this->{dialogRadioButton} = createRadioButton(this->tr('Dialog'));
    this->{sheetRadioButton} = createRadioButton(this->tr('Sheet'));
    this->{drawerRadioButton} = createRadioButton(this->tr('Drawer'));
    this->{popupRadioButton} = createRadioButton(this->tr('Popup'));
    this->{toolRadioButton} = createRadioButton(this->tr('Tool'));
    this->{toolTipRadioButton} = createRadioButton(this->tr('Tooltip'));
    this->{splashScreenRadioButton} = createRadioButton(this->tr('Splash screen'));
    this->{windowRadioButton}->setChecked(1);

    my $layout = Qt::GridLayout();
    $layout->addWidget(this->windowRadioButton, 0, 0);
    $layout->addWidget(this->dialogRadioButton, 1, 0);
    $layout->addWidget(this->sheetRadioButton, 2, 0);
    $layout->addWidget(this->drawerRadioButton, 3, 0);
    $layout->addWidget(this->popupRadioButton, 0, 1);
    $layout->addWidget(this->toolRadioButton, 1, 1);
    $layout->addWidget(this->toolTipRadioButton, 2, 1);
    $layout->addWidget(this->splashScreenRadioButton, 3, 1);
    this->typeGroupBox->setLayout($layout);
}
# [5]

# [6]
sub createHintsGroupBox {
    this->{hintsGroupBox} = Qt::GroupBox(this->tr('Hints'));

    this->{msWindowsFixedSizeDialogCheckBox} =
            this->createCheckBox(this->tr('MS Windows fixed size dialog'));
    this->{x11BypassWindowManagerCheckBox} =
            this->createCheckBox(this->tr('X11 bypass window manager'));
    this->{framelessWindowCheckBox} = this->createCheckBox(this->tr('Frameless window'));
    this->{windowTitleCheckBox} = this->createCheckBox(this->tr('Window title'));
    this->{windowSystemMenuCheckBox} = this->createCheckBox(this->tr('Window system menu'));
    this->{windowMinimizeButtonCheckBox} = this->createCheckBox(this->tr('Window minimize button'));
    this->{windowMaximizeButtonCheckBox} = this->createCheckBox(this->tr('Window maximize button'));
    this->{windowCloseButtonCheckBox} = this->createCheckBox(this->tr('Window close button'));
    this->{windowContextHelpButtonCheckBox} =
            this->createCheckBox(this->tr('Window context help button'));
    this->{windowShadeButtonCheckBox} = this->createCheckBox(this->tr('Window shade button'));
    this->{windowStaysOnTopCheckBox} = this->createCheckBox(this->tr('Window stays on top'));
    this->{windowStaysOnBottomCheckBox} = this->createCheckBox(this->tr('Window stays on bottom'));
    this->{customizeWindowHintCheckBox} = this->createCheckBox(this->tr('Customize window'));

    my $layout = Qt::GridLayout();
    $layout->addWidget(this->msWindowsFixedSizeDialogCheckBox, 0, 0);
    $layout->addWidget(this->x11BypassWindowManagerCheckBox, 1, 0);
    $layout->addWidget(this->framelessWindowCheckBox, 2, 0);
    $layout->addWidget(this->windowTitleCheckBox, 3, 0);
    $layout->addWidget(this->windowSystemMenuCheckBox, 4, 0);
    $layout->addWidget(this->windowMinimizeButtonCheckBox, 0, 1);
    $layout->addWidget(this->windowMaximizeButtonCheckBox, 1, 1);
    $layout->addWidget(this->windowCloseButtonCheckBox, 2, 1);
    $layout->addWidget(this->windowContextHelpButtonCheckBox, 3, 1);
    $layout->addWidget(this->windowShadeButtonCheckBox, 4, 1);
    $layout->addWidget(this->windowStaysOnTopCheckBox, 5, 1);
    $layout->addWidget(this->windowStaysOnBottomCheckBox, 6, 1);
    $layout->addWidget(this->customizeWindowHintCheckBox, 5, 0);
    this->hintsGroupBox->setLayout($layout);
}
# [6]

# [7]
sub createCheckBox {
    my ($text) = @_;
    my $checkBox = Qt::CheckBox($text);
    this->connect($checkBox, SIGNAL 'clicked()', this, SLOT 'updatePreview()');
    return $checkBox;
}
# [7]

# [8]
sub createRadioButton {
    my ($text) = @_;
    my $button = Qt::RadioButton($text);
    this->connect($button, SIGNAL 'clicked()', this, SLOT 'updatePreview()');
    return $button;
}
# [8]

1;
