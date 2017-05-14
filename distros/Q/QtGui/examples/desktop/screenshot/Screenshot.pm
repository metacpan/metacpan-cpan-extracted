package Screenshot;

use Qt;
use Qt::QSize;
use Qt::QString;
use Qt::QByteArray;
use Qt::QTimer;
use Qt::QDir;
use Qt::QPixmap;
use Qt::QWidget;
use Qt::QDesktopWidget;
use Qt::QCheckBox;
use Qt::QGridLayout;
use Qt::QGroupBox;
use Qt::QBoxLayout;
use Qt::QLabel;
use Qt::QSizePolicy;
use Qt::QPushButton;
use Qt::QSpinBox;
use Qt::QApplication;
use Qt::QFileDialog;

our @ISA=qw(Qt::QWidget);

our @EXPORT=qw(Screenshot);

sub Screenshot {
    my $class = 'Screenshot';
    my @signals = ();
    my @slots = ('newScreenshot()', 'saveScreenshot()', 'shootScreen()', 'updateCheckBox()');
    my $this = QWidget(\@signals, \@slots);
    bless $this, $class;
    
    $this->{screenshotLabel} = QLabel();
    $this->{screenshotLabel}->setSizePolicy(Qt::QSizePolicy::Expanding, Qt::QSizePolicy::Expanding);
    $this->{screenshotLabel}->setAlignment(Qt::AlignCenter);
    $this->{screenshotLabel}->setMinimumSize(240, 160);

    $this->createOptionsGroupBox();
    $this->createButtonsLayout();

    $this->{mainLayout} = QVBoxLayout();
    $this->{mainLayout}->addWidget($this->{screenshotLabel});
    $this->{mainLayout}->addWidget($this->{optionsGroupBox});
    $this->{mainLayout}->addLayout($this->{buttonsLayout});
    $this->setLayout($this->{mainLayout});

    $this->shootScreen();
    $this->{delaySpinBox}->setValue(5);

    $this->setWindowTitle(TR("Screenshot"));
    $this->resize(300, 200);
    
    return $this;
}

sub resizeEvent { #(QResizeEvent * /* event */)
    my $this = shift;
    my $scaledSize = $this->{originalPixmap}->size();
    $scaledSize->scale($this->{screenshotLabel}->size(), Qt::KeepAspectRatio);
    unless ( $this->{screenshotLabel}->pixmap() and $scaledSize == $this->{screenshotLabel}->pixmap()->size() ) {
        $this->updateScreenshotLabel();
    }
}

sub newScreenshot {
    my $this = shift;
    $this->hide() if $this->{hideThisWindowCheckBox}->isChecked();
        
    $this->{newScreenshotButton}->setDisabled(1); # true

    Qt::QTimer::singleShot($this->{delaySpinBox}->value() * 1000, $this, SLOT('shootScreen()'));
}

sub saveScreenshot {
    my $this = shift;
    my $format = QString("png");
    my $initialPath = Qt::QDir::currentPath();
    $initialPath += TR("/untitled.");
    $initialPath += $format;

    my $fileName = Qt::QFileDialog::getSaveFileName($this, TR("Save As"), $initialPath, 
	    TR("%1 Files (*.%2);;All Files (*)")->arg($format->toUpper())->arg($format));
    unless ( $fileName->isEmpty() ) {
        $this->{originalPixmap}->save($fileName, $format->toAscii()->data());
    }
}

sub shootScreen {
    my $this = shift;
    $qApp->beep() if $this->{delaySpinBox}->value() != 0;
    $this->{originalPixmap} = Qt::QPixmap::grabWindow( Qt::QApplication::desktop()->winId() );
    $this->updateScreenshotLabel();

    $this->{newScreenshotButton}->setDisabled(0); # false
    if ( $this->{hideThisWindowCheckBox}->isChecked() ) {
        $this->show();
    }
}

sub updateCheckBox {
    my $this = shift;
    if ( $this->{delaySpinBox}->value() == 0) {
        $this->{hideThisWindowCheckBox}->setDisabled(1); # true
    }
    else {
        $this->{hideThisWindowCheckBox}->setDisabled(0); # false
    }
}

sub createOptionsGroupBox {
    my $this = shift;
    $this->{optionsGroupBox} = QGroupBox(TR("Options"));

    $this->{delaySpinBox} = QSpinBox();
    $this->{delaySpinBox}->setSuffix(TR(" s"));
    $this->{delaySpinBox}->setMaximum(60);
    $this->connect($this->{delaySpinBox}, SIGNAL('valueChanged(int)'), $this, SLOT('updateCheckBox()'));

    $this->{delaySpinBoxLabel} = QLabel(TR("Screenshot Delay:"));

    $this->{hideThisWindowCheckBox} = QCheckBox(TR("Hide This Window"));

    $this->{optionsGroupBoxLayout} = QGridLayout();
    $this->{optionsGroupBoxLayout}->addWidget($this->{delaySpinBoxLabel}, 0, 0);
    $this->{optionsGroupBoxLayout}->addWidget($this->{delaySpinBox}, 0, 1);
    $this->{optionsGroupBoxLayout}->addWidget($this->{hideThisWindowCheckBox}, 1, 0, 1, 2);
    $this->{optionsGroupBox}->setLayout($this->{optionsGroupBoxLayout});
}

sub createButtonsLayout {
    my $this = shift;
    $this->{newScreenshotButton} = $this->createButton(TR("New Screenshot"), $this, SLOT('newScreenshot()'));

    $this->{saveScreenshotButton} = $this->createButton(TR("Save Screenshot"), $this, SLOT('saveScreenshot()'));

    $this->{quitScreenshotButton} = $this->createButton(TR("Quit"), $this, SLOT('close()'));

    $this->{buttonsLayout} = QHBoxLayout();
    $this->{buttonsLayout}->addStretch();
    $this->{buttonsLayout}->addWidget($this->{newScreenshotButton});
    $this->{buttonsLayout}->addWidget($this->{saveScreenshotButton});
    $this->{buttonsLayout}->addWidget($this->{quitScreenshotButton});
}

sub createButton{ # const QString &text, QWidget *receiver, const char *member)
    my $this = shift;
    my $text = shift;
    my $receiver = shift;
    my $member = shift;
    my $button = QPushButton($text);
    $button->connect($button, SIGNAL('clicked()'), $receiver, $member);
    return $button;
}

sub updateScreenshotLabel {
    my $this = shift;
    $this->{screenshotLabel}->setPixmap($this->{originalPixmap}->scaled($this->{screenshotLabel}->size(),
	    Qt::KeepAspectRatio, Qt::SmoothTransformation) );
}


1;
