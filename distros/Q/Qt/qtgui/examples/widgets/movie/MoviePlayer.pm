package MoviePlayer;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    open => [],
    goToFrame => ['int'],
    fitToWindow => [],
    updateButtons => [],
    updateFrameSlider => [];

sub currentMovieDirectory() {
    return this->{currentMovieDirectory};
}

sub movieLabel() {
    return this->{movieLabel};
}

sub movie() {
    return this->{movie};
}

sub openButton() {
    return this->{openButton};
}

sub playButton() {
    return this->{playButton};
}

sub pauseButton() {
    return this->{pauseButton};
}

sub stopButton() {
    return this->{stopButton};
}

sub quitButton() {
    return this->{quitButton};
}

sub fitCheckBox() {
    return this->{fitCheckBox};
}

sub frameSlider() {
    return this->{frameSlider};
}

sub speedSpinBox() {
    return this->{speedSpinBox};
}

sub frameLabel() {
    return this->{frameLabel};
}

sub speedLabel() {
    return this->{speedLabel};
}

sub controlsLayout() {
    return this->{controlsLayout};
}

sub buttonsLayout() {
    return this->{buttonsLayout};
}

sub mainLayout() {
    return this->{mainLayout};
}


sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    my $movie = Qt::Movie(this);
    this->{movie} = $movie;
    $movie->setCacheMode(Qt::Movie::CacheAll());

    my $movieLabel = Qt::Label(this->tr('No movie loaded'));
    this->{movieLabel} = $movieLabel;
    $movieLabel->setAlignment(Qt::AlignCenter());
    $movieLabel->setSizePolicy(Qt::SizePolicy::Ignored(), Qt::SizePolicy::Ignored());
    $movieLabel->setBackgroundRole(Qt::Palette::Dark());
    $movieLabel->setAutoFillBackground(1);

    my $currentMovieDirectory = 'movies';
    this->{currentMovieDirectory} = $currentMovieDirectory;

    this->createControls();
    this->createButtons();

    this->connect($movie, SIGNAL 'frameChanged(int)', this, SLOT 'updateFrameSlider()');
    this->connect($movie, SIGNAL 'stateChanged(QMovie::MovieState)',
            this, SLOT 'updateButtons()');
    this->connect(this->fitCheckBox, SIGNAL 'clicked()', this, SLOT 'fitToWindow()');
    this->connect(this->frameSlider, SIGNAL 'valueChanged(int)', this, SLOT 'goToFrame(int)');
    this->connect(this->speedSpinBox, SIGNAL 'valueChanged(int)',
            $movie, SLOT 'setSpeed(int)');

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget($movieLabel);
    $mainLayout->addLayout(this->controlsLayout);
    $mainLayout->addLayout(this->buttonsLayout);
    this->setLayout($mainLayout);

    this->updateFrameSlider();
    this->updateButtons();

    this->setWindowTitle(this->tr('Movie Player'));
    this->resize(400, 400);
}

sub open {
    my $fileName = Qt::FileDialog::getOpenFileName(this, this->tr('Open a Movie'),
                               this->currentMovieDirectory);
    if ($fileName) {
        this->openFile($fileName);
    }
}

sub openFile {
    my ($fileName) = @_;
    this->{currentMovieDirectory} = Qt::FileInfo($fileName)->path();

    this->movie->stop();
    this->movieLabel->setMovie(this->movie);
    this->movie->setFileName($fileName);
    this->movie->start();

    this->updateFrameSlider();
    this->updateButtons();
}

sub goToFrame {
    my ( $frame ) = @_;
    this->movie->jumpToFrame($frame);
}

sub fitToWindow {
    this->movieLabel->setScaledContents(this->fitCheckBox->isChecked());
}

sub updateFrameSlider {
    my $hasFrames = this->movie->currentFrameNumber() >= 0;

    if ($hasFrames) {
        if (this->movie->frameCount() > 0) {
            this->frameSlider->setMaximum(this->movie->frameCount() - 1);
        } else {
            if (this->movie->currentFrameNumber() > this->frameSlider->maximum()) {
                this->frameSlider->setMaximum(this->movie->currentFrameNumber());
            }
        }
        this->frameSlider->setValue(this->movie->currentFrameNumber());
    } else {
        this->frameSlider->setMaximum(0);
    }
    this->frameLabel->setEnabled($hasFrames);
    this->frameSlider->setEnabled($hasFrames);
}

sub updateButtons {
    this->playButton->setEnabled(this->movie->isValid() && this->movie->frameCount() != 1
                           && this->movie->state() == Qt::Movie::NotRunning());
    this->pauseButton->setEnabled(this->movie->state() != Qt::Movie::NotRunning());
    this->pauseButton->setChecked(this->movie->state() == Qt::Movie::Paused());
    this->stopButton->setEnabled(this->movie->state() != Qt::Movie::NotRunning());
}

sub createControls {
    my $fitCheckBox = Qt::CheckBox(this->tr('Fit to Window'));
    this->{fitCheckBox} = $fitCheckBox;

    my $frameLabel = Qt::Label(this->tr('Current frame:'));
    this->{frameLabel} = $frameLabel;

    my $frameSlider = Qt::Slider(Qt::Horizontal());
    this->{frameSlider} = $frameSlider;
    this->frameSlider->setTickPosition(Qt::Slider::TicksBelow());
    this->frameSlider->setTickInterval(10);

    my $speedLabel = Qt::Label(this->tr('Speed:'));
    this->{speedLabel} = $speedLabel;

    my $speedSpinBox = Qt::SpinBox();
    this->{speedSpinBox} = $speedSpinBox;
    this->speedSpinBox->setRange(1, 9999);
    this->speedSpinBox->setValue(100);
    this->speedSpinBox->setSuffix(this->tr('%'));

    my $controlsLayout = Qt::GridLayout();
    this->{controlsLayout} = $controlsLayout;
    this->controlsLayout->addWidget($fitCheckBox, 0, 0, 1, 2);
    this->controlsLayout->addWidget($frameLabel, 1, 0);
    this->controlsLayout->addWidget($frameSlider, 1, 1, 1, 2);
    this->controlsLayout->addWidget($speedLabel, 2, 0);
    this->controlsLayout->addWidget($speedSpinBox, 2, 1);
}

sub createButtons {
    my $iconSize = Qt::Size(36, 36);

    my $openButton = Qt::ToolButton();
    this->{openButton} = $openButton;
    $openButton->setIcon(this->style()->standardIcon(Qt::Style::SP_DialogOpenButton()));
    $openButton->setIconSize($iconSize);
    $openButton->setToolTip(this->tr('Open File'));
    this->connect($openButton, SIGNAL 'clicked()', this, SLOT 'open()');

    my $playButton = Qt::ToolButton();
    this->{playButton} = $playButton;
    $playButton->setIcon(this->style()->standardIcon(Qt::Style::SP_MediaPlay()));
    $playButton->setIconSize($iconSize);
    $playButton->setToolTip(this->tr('Play'));
    this->connect($playButton, SIGNAL 'clicked()', this->movie, SLOT 'start()');

    my $pauseButton = Qt::ToolButton();
    this->{pauseButton} = $pauseButton;
    $pauseButton->setCheckable(1);
    $pauseButton->setIcon(this->style()->standardIcon(Qt::Style::SP_MediaPause()));
    $pauseButton->setIconSize($iconSize);
    $pauseButton->setToolTip(this->tr('Pause'));
    this->connect($pauseButton, SIGNAL 'clicked(bool)', this->movie, SLOT 'setPaused(bool)');

    my $stopButton = Qt::ToolButton();
    this->{stopButton} = $stopButton;
    $stopButton->setIcon(this->style()->standardIcon(Qt::Style::SP_MediaStop()));
    $stopButton->setIconSize($iconSize);
    $stopButton->setToolTip(this->tr('Stop'));
    this->connect($stopButton, SIGNAL 'clicked()', this->movie, SLOT 'stop()');

    my $quitButton = Qt::ToolButton();
    this->{quitButton} = $quitButton;
    $quitButton->setIcon(this->style()->standardIcon(Qt::Style::SP_DialogCloseButton()));
    $quitButton->setIconSize($iconSize);
    $quitButton->setToolTip(this->tr('Quit'));
    this->connect($quitButton, SIGNAL 'clicked()', this, SLOT 'close()');

    my $buttonsLayout = Qt::HBoxLayout();
    this->{buttonsLayout} = $buttonsLayout;
    $buttonsLayout->addStretch();
    $buttonsLayout->addWidget($openButton);
    $buttonsLayout->addWidget($playButton);
    $buttonsLayout->addWidget($pauseButton);
    $buttonsLayout->addWidget($stopButton);
    $buttonsLayout->addWidget($quitButton);
    $buttonsLayout->addStretch();
}

1;
