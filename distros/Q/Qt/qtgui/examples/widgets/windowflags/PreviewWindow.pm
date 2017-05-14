package PreviewWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;

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
sub textEdit() {
    return this->{textEdit};
}

sub closeButton() {
    return this->{closeButton};
}
# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    my $textEdit = this->{textEdit} = Qt::TextEdit();
    $textEdit->setReadOnly(1);
    $textEdit->setLineWrapMode(Qt::TextEdit::NoWrap());

    my $closeButton = this->{closeButton} = Qt::PushButton(this->tr('&Close'));
    this->connect($closeButton, SIGNAL 'clicked()', this, SLOT 'close()');

    my $layout = Qt::VBoxLayout();
    $layout->addWidget($textEdit);
    $layout->addWidget($closeButton);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('Preview'));
}
# [0]

# [1]
sub setWindowFlags {
    my ($flags) = @_;
    this->SUPER::setWindowFlags($flags);

    my $text;

    my $type = ($flags & Qt::WindowType_Mask());
    if ($type == Qt::Window()) {
        $text = 'Qt::Window';
    } elsif ($type == Dialog) {
        $text = 'Qt::Dialog';
    } elsif ($type == Qt::Sheet()) {
        $text = 'Qt::Sheet';
    } elsif ($type == Qt::Drawer()) {
        $text = 'Qt::Drawer';
    } elsif ($type == Qt::Popup()) {
        $text = 'Qt::Popup';
    } elsif ($type == Qt::Tool()) {
        $text = 'Qt::Tool';
    } elsif ($type == ToolTip) {
        $text = 'Qt::ToolTip';
    } elsif ($type == SplashScreen) {
        $text = 'Qt::SplashScreen';
    }

    if (${$flags & Qt::MSWindowsFixedSizeDialogHint()}) {
        $text .= "\n| Qt::MSWindowsFixedSizeDialogHint";
    }
    if (${$flags & Qt::X11BypassWindowManagerHint()}) {
        $text .= "\n| Qt::X11BypassWindowManagerHint";
    }
    if (${$flags & Qt::FramelessWindowHint()}) {
        $text .= "\n| Qt::FramelessWindowHint";
    }
    if (${$flags & Qt::WindowTitleHint()}) {
        $text .= "\n| Qt::WindowTitleHint";
    }
    if (${$flags & Qt::WindowSystemMenuHint()}) {
        $text .= "\n| Qt::WindowSystemMenuHint";
    }
    if (${$flags & Qt::WindowMinimizeButtonHint()}) {
        $text .= "\n| Qt::WindowMinimizeButtonHint";
    }
    if (${$flags & Qt::WindowMaximizeButtonHint()}) {
        $text .= "\n| Qt::WindowMaximizeButtonHint";
    }
    if (${$flags & Qt::WindowCloseButtonHint()}) {
        $text .= "\n| Qt::WindowCloseButtonHint";
    }
    if (${$flags & Qt::WindowContextHelpButtonHint()}) {
        $text .= "\n| Qt::WindowContextHelpButtonHint";
    }
    if (${$flags & Qt::WindowShadeButtonHint()}) {
        $text .= "\n| Qt::WindowShadeButtonHint";
    }
    if (${$flags & Qt::WindowStaysOnTopHint()}) {
        $text .= "\n| Qt::WindowStaysOnTopHint";
    }
    if (${$flags & Qt::CustomizeWindowHint()}) {
        $text .= "\n| Qt::CustomizeWindowHint";
    }

    this->textEdit->setPlainText($text);
}
# [1]

1;
