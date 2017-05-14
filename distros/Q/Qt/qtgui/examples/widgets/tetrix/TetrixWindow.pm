package TetrixWindow;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use TetrixBoard;

# [0]
#    TetrixBoard *board;
#    Qt::Label *nextPieceLabel;
#    Qt::LCDNumber *scoreLcd;
#    Qt::LCDNumber *levelLcd;
#    Qt::LCDNumber *linesLcd;
#    Qt::PushButton *startButton;
#    Qt::PushButton *quitButton;
#    Qt::PushButton *pauseButton;
# [0]

# [0]
sub NEW {
    my( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    my $board = TetrixBoard();
    this->{board} = $board;
# [0]

    my $nextPieceLabel = Qt::Label();
    this->{nextPieceLabel} = $nextPieceLabel;
    $nextPieceLabel->setFrameStyle(Qt::Frame::Box() | Qt::Frame::Raised());
    $nextPieceLabel->setAlignment(Qt::AlignCenter());
    $board->setNextPieceLabel($nextPieceLabel);

# [1]
    my $scoreLcd = Qt::LCDNumber(5);
    this->{scoreLcd} = $scoreLcd;
    $scoreLcd->setSegmentStyle(Qt::LCDNumber::Filled());
# [1]
    my $levelLcd = Qt::LCDNumber(2);
    this->{levelLcd} = $levelLcd;
    $levelLcd->setSegmentStyle(Qt::LCDNumber::Filled());
    my $linesLcd = Qt::LCDNumber(5);
    this->{linesLcd} = $linesLcd;
    $linesLcd->setSegmentStyle(Qt::LCDNumber::Filled());

# [2]
    my $startButton = Qt::PushButton(this->tr('&Start'));
    this->{startButton} = $startButton;
    $startButton->setFocusPolicy(Qt::NoFocus());
    my $quitButton = Qt::PushButton(this->tr('&Quit'));
    this->{quitButton} = $quitButton;
    $quitButton->setFocusPolicy(Qt::NoFocus());
    my $pauseButton = Qt::PushButton(this->tr('&Pause'));
    this->{pauseButton} = $pauseButton;
# [2] //! [3]
    $pauseButton->setFocusPolicy(Qt::NoFocus());
# [3] //! [4]

    this->connect($startButton, SIGNAL 'clicked()', $board, SLOT 'start()');
# [4] //! [5]
    this->connect($quitButton , SIGNAL 'clicked()', qApp, SLOT 'quit()');
    this->connect($pauseButton, SIGNAL 'clicked()', $board, SLOT 'pause()');
    this->connect($board, SIGNAL 'scoreChanged(int)', $scoreLcd, SLOT 'display(int)');
    this->connect($board, SIGNAL 'levelChanged(int)', $levelLcd, SLOT 'display(int)');
    this->connect($board, SIGNAL 'linesRemovedChanged(int)',
            $linesLcd, SLOT 'display(int)');
# [5]

# [6]
    my $layout = Qt::GridLayout();
    $layout->addWidget(createLabel(this->tr('NEXT')), 0, 0);
    $layout->addWidget($nextPieceLabel, 1, 0);
    $layout->addWidget(createLabel(this->tr('LEVEL')), 2, 0);
    $layout->addWidget($levelLcd, 3, 0);
    $layout->addWidget($startButton, 4, 0);
    $layout->addWidget($board, 0, 1, 6, 1);
    $layout->addWidget(createLabel(this->tr('SCORE')), 0, 2);
    $layout->addWidget($scoreLcd, 1, 2);
    $layout->addWidget(createLabel(this->tr('LINES REMOVED')), 2, 2);
    $layout->addWidget($linesLcd, 3, 2);
    $layout->addWidget($quitButton, 4, 2);
    $layout->addWidget($pauseButton, 5, 2);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('Tetrix'));
    this->resize(550, 370);
}
# [6]

# [7]
sub createLabel {
    my ( $text ) = @_;
    my $lbl = Qt::Label($text);
    $lbl->setAlignment(Qt::AlignHCenter() | Qt::AlignBottom());
    return $lbl;
}
# [7]

1;
