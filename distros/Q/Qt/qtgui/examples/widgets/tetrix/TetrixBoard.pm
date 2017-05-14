package TetrixBoard;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Frame );
use TetrixPiece;

# [0]
use QtCore4::slots
    start => [],
    pause => [];

use QtCore4::signals
    scoreChanged => ['int'],
    levelChanged => ['int'],
    linesRemovedChanged => ['int'];
# [0]

# [1]
use constant { BoardWidth => 10, BoardHeight => 22 };

my @colorTable = (
    0x000000, 0xCC6666, 0x66CC66, 0x6666CC,
    0xCCCC66, 0xCC66CC, 0x66CCCC, 0xDAAA00
);

sub shapeAt {
    my ($x, $y) = @_;
    this->{board}->[($y * BoardWidth) + $x];
}

sub setShapeAt {
    my ($x, $y, $shape) = @_;
    this->{board}->[($y * BoardWidth) + $x] = $shape;
}

sub timeoutTime {
    return int( 1000 / (1 + this->level()) );
}

sub squareWidth {
    return int( this->contentsRect()->width() / BoardWidth );
}

sub squareHeight {
    return int( this->contentsRect()->height() / BoardHeight );
}

sub timer() {
    return this->{timer};
}

sub nextPieceLabel() {
    return this->{nextPieceLabel};
}

sub isStarted() {
    return this->{isStarted};
}

sub isPaused() {
    return this->{isPaused};
}

sub isWaitingAfterLine() {
    return this->{isWaitingAfterLine};
}

sub curPiece() {
    return this->{curPiece};
}

sub nextPiece() {
    return this->{nextPiece};
}

sub curX() {
    return this->{curX};
}

sub curY() {
    return this->{curY};
}

sub numLinesRemoved() {
    return this->{numLinesRemoved};
}

sub numPiecesDropped() {
    return this->{numPiecesDropped};
}

sub score() {
    return this->{score};
}

sub level() {
    return this->{level};
}

sub board() {
    return this->{board};
}

# [1]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setFrameStyle(Qt::Frame::Panel() | Qt::Frame::Sunken());
    this->setFocusPolicy(Qt::StrongFocus());
    this->{isStarted} = 0;
    this->{isPaused} = 0;
    this->clearBoard();

    this->{curPiece} = TetrixPiece();
    this->{nextPiece} = TetrixPiece();
    this->{nextPiece}->setRandomShape();
    this->{timer} = Qt::BasicTimer();
}
# [0]

# [1]
sub setNextPieceLabel {
    my ($label) = @_;
    this->{nextPieceLabel} = $label;
}
# [1]

# [2]
sub sizeHint {
    return Qt::Size(BoardWidth * 15 + this->frameWidth() * 2,
                 BoardHeight * 15 + this->frameWidth() * 2);
}

sub minimumSizeHint {
# [2] //! [3]
    return Qt::Size(BoardWidth * 5 + this->frameWidth() * 2,
                 BoardHeight * 5 + this->frameWidth() * 2);
}
# [3]

# [4]
sub start {
    if (this->{isPaused}) {
        return;
    }

    this->{isStarted} = 1;
    this->{isWaitingAfterLine} = 0;
    this->{numLinesRemoved} = 0;
    this->{numPiecesDropped} = 0;
    this->{score} = 0;
    this->{level} = 1;
    this->clearBoard();

    emit linesRemovedChanged(this->{numLinesRemoved});
    emit scoreChanged(this->{score});
    emit levelChanged(this->{level});

    this->newPiece();
    this->timer->start(this->timeoutTime(), this);
}
# [4]

# [5]
sub pause {
    if (!this->{isStarted}) {
        return;
    }

    my $isPaused = this->{isPaused};
    $isPaused = !$isPaused;
    if ($isPaused) {
        this->timer->stop();
    } else {
        this->timer->start(this->timeoutTime(), this);
    }
    this->update();
    this->{isPaused} = $isPaused;
# [5] //! [6]
}
# [6]

# [7]
sub paintEvent {
    my ($event) = @_;
    this->SUPER::paintEvent($event);

    my $painter = Qt::Painter(this);
    my $rect = this->contentsRect();
# [7]

    if (this->{isPaused}) {
        $painter->drawText($rect, Qt::AlignCenter(), this->tr('Pause'));
        $painter->end();
        return;
    }

# [8]
    my $boardTop = $rect->bottom() - BoardHeight*this->squareHeight();

    for (my $i = 0; $i < BoardHeight; ++$i) {
        for (my $j = 0; $j < BoardWidth; ++$j) {
            my $shape = shapeAt($j, BoardHeight - $i - 1);
            if ($shape != TetrixPiece::NoShape) {
                this->drawSquare($painter, $rect->left() + $j * this->squareWidth(),
                        $boardTop + $i * this->squareHeight(), $shape);
            }
        }
# [8] //! [9]
    }
# [9]

# [10]
    my $curPiece = this->{curPiece};
    if ($curPiece->shape() != TetrixPiece::NoShape) {
        for (my $i = 0; $i < 4; ++$i) {
            my $curX = this->{curX};
            my $curY = this->{curY};
            my $x = curX + $curPiece->x($i);
            my $y = curY - $curPiece->y($i);
            this->drawSquare($painter, $rect->left() + $x * this->squareWidth(),
                       $boardTop + (BoardHeight - $y - 1) * this->squareHeight(),
                       $curPiece->shape());
        }
# [10] //! [11]
    }
# [11] //! [12]
    $painter->end();
}
# [12]

# [13]
sub keyPressEvent {
    my ($event) = @_;
    my $isStarted = this->{isStarted};
    my $isPaused = this->{isPaused};
    my $curPiece = this->{curPiece};
    if (!$isStarted || $isPaused || curPiece->shape() == TetrixPiece::NoShape) {
        this->SUPER::keyPressEvent($event);
        return;
    }
# [13]

# [14]
    my $curX = this->{curX};
    my $curY = this->{curY};
    if( $event->key() == Qt::Key_Left() ) {
        this->tryMove($curPiece, $curX - 1, $curY);
    }
    elsif( $event->key() == Qt::Key_Right() ) {
        this->tryMove($curPiece, $curX + 1, $curY);
    }
    elsif( $event->key() == Qt::Key_Down() ) {
        this->tryMove($curPiece->rotatedRight(), $curX, $curY);
    }
    elsif( $event->key() == Qt::Key_Up() ) {
        this->tryMove($curPiece->rotatedLeft(), $curX, $curY);
    }
    elsif( $event->key() == Qt::Key_Space() ) {
        this->dropDown();
    }
    elsif( $event->key() == Qt::Key_D() ) {
        this->oneLineDown();
    }
    else {
        this->SUPER::keyPressEvent($event);
    }
# [14]
}

# [15]
sub timerEvent {
    my ($event) = @_;
    if ($event->timerId() == this->timer->timerId()) {
        if (this->{isWaitingAfterLine}) {
            this->{isWaitingAfterLine} = 0;
            this->newPiece();
            this->timer->start(this->timeoutTime(), this);
        } else {
            this->oneLineDown();
        }
    } else {
        this->SUPER::timerEvent($event);
# [15] //! [16]
    }
# [16] //! [17]
}
# [17]

# [18]
sub clearBoard {
    this->{board} = [];
    for (my $i = 0; $i < BoardHeight * BoardWidth; ++$i) {
        this->{board}->[$i] = TetrixPiece::NoShape;
    }
}
# [18]

# [19]
sub dropDown {
    my $dropHeight = 0;
    my $curX = this->{curX};
    my $curY = this->{curY};
    my $newY = $curY;
    my $curPiece = this->{curPiece};
    while ($newY > 0) {
        if (!this->tryMove($curPiece, $curX, $newY - 1)) {
            last;
        }
        --$newY;
        ++$dropHeight;
    }
    this->pieceDropped($dropHeight);
# [19] //! [20]
}
# [20]

# [21]
sub oneLineDown {
    if (!this->tryMove(this->curPiece(), this->curX(), this->curY() - 1)) {
	    this->pieceDropped(0);
    }
}
# [21]

# [22]
sub pieceDropped {
    my ($dropHeight) = @_;
    my $curX = this->{curX};
    my $curY = this->{curY};
    my $curPiece = this->{curPiece};
    for (my $i = 0; $i < 4; ++$i) {
        my $x = $curX + $curPiece->x($i);
        my $y = $curY - $curPiece->y($i);
        this->setShapeAt($x, $y, $curPiece->shape());
    }

    ++(this->{numPiecesDropped});
    if (this->numPiecesDropped() % 25 == 0) {
        ++(this->{level});
        this->timer->start(this->timeoutTime(), this);
        emit levelChanged(this->{level});
    }

    this->{score} += $dropHeight + 7;
    emit scoreChanged(this->score());
    this->removeFullLines();

    if (!this->{isWaitingAfterLine}) {
        this->newPiece();
    }
# [22] //! [23]
}
# [23]

# [24]
sub removeFullLines {
    my $numFullLines = 0;

    for (my $i = BoardHeight - 1; $i >= 0; --$i) {
        my $lineIsFull = 1;

        for (my $j = 0; $j < BoardWidth; ++$j) {
            if (this->shapeAt($j, $i) == TetrixPiece::NoShape) {
                $lineIsFull = 0;
                last;
            }
        }

        if ($lineIsFull) {
# [24] //! [25]
            ++$numFullLines;

            for (my $k = $i; $k < BoardHeight - 1; ++$k) {
                for (my $j = 0; $j < BoardWidth; ++$j) {
                    this->setShapeAt($j, $k, this->shapeAt($j, $k + 1) );
                }
            }
# [25] //! [26]
            for (my $j = 0; $j < BoardWidth; ++$j) {
                this->setShapeAt($j, BoardHeight - 1, TetrixPiece::NoShape);
            }
        }
# [26] //! [27]
    }
# [27]

# [28]
    if ($numFullLines > 0) {
        this->{numLinesRemoved} += $numFullLines;
        this->{score} += 10 * $numFullLines;
        emit linesRemovedChanged(this->{numLinesRemoved});
        emit scoreChanged(this->{score});

        this->timer->start(500, this);
        this->{isWaitingAfterLine} = 1;
        this->{curPiece}->setShape(TetrixPiece::NoShape);
        this->update();
    }
# [28] //! [29]
}
# [29]

# [30]
sub newPiece {
    this->{curPiece} = this->nextPiece;
    # Have to make a new piece, otherwise curPiece always equals nextPiece
    this->{nextPiece} = TetrixPiece();
    this->nextPiece->setRandomShape();
    this->showNextPiece();
    this->{curX} = BoardWidth / 2 + 1;
    this->{curY} = BoardHeight - 1 + this->curPiece->minY();

    if (!this->tryMove(this->curPiece, this->curX, this->curY)) {
        this->curPiece->setShape(TetrixPiece::NoShape);
        this->timer->stop();
        this->{isStarted} = 0;
    }
# [30] //! [31]
}
# [31]

# [32]
sub showNextPiece {
    if (!this->nextPieceLabel) {
        return;
    }

    my $dx = this->nextPiece->maxX() - this->nextPiece->minX() + 1;
    my $dy = this->nextPiece->maxY() - this->nextPiece->minY() + 1;

    my $pixmap = Qt::Pixmap($dx * this->squareWidth(), $dy * this->squareHeight());
    my $painter = Qt::Painter($pixmap);
    $painter->fillRect($pixmap->rect(), this->nextPieceLabel->palette()->background());

    for (my $i = 0; $i < 4; ++$i) {
        my $x = this->nextPiece->x($i) - this->nextPiece->minX();
        my $y = this->nextPiece->y($i) - this->nextPiece->minY();
        this->drawSquare($painter, $x * this->squareWidth(), $y * this->squareHeight(),
                   this->nextPiece->shape());
    }
    this->nextPieceLabel->setPixmap($pixmap);
# [32] //! [33]
    $painter->end();
}
# [33]

# [34]
sub tryMove {
    my ($newPiece, $newX, $newY) = @_;
    for (my $i = 0; $i < 4; ++$i) {
        my $x = $newX + $newPiece->x($i);
        my $y = $newY - $newPiece->y($i);
        if ($x < 0 || $x >= BoardWidth || $y < 0 || $y >= BoardHeight) {
            return 0;
        }
        if (this->shapeAt($x, $y) != TetrixPiece::NoShape) {
            return 0;
        }
    }
# [34]

# [35]
    this->{curPiece} = $newPiece;
    this->{curX} = $newX;
    this->{curY} = $newY;
    this->update();
    return 1;
}
# [35]

# [36]
sub drawSquare {
    my ($painter, $x, $y, $shape) = @_;

    my $color = Qt::Color($colorTable[int $shape]);
    $painter->fillRect($x + 1, $y + 1, this->squareWidth() - 2, this->squareHeight() - 2,
                     Qt::Brush($color));

    $painter->setPen($color->light());
    $painter->drawLine($x, $y + this->squareHeight() - 1, $x, $y);
    $painter->drawLine($x, $y, $x + this->squareWidth() - 1, $y);

    $painter->setPen($color->dark());
    $painter->drawLine($x + 1, $y + this->squareHeight() - 1,
                     $x + this->squareWidth() - 1, $y + this->squareHeight() - 1);
    $painter->drawLine($x + this->squareWidth() - 1, $y + this->squareHeight() - 1,
                     $x + this->squareWidth() - 1, $y + 1);
}
# [36]

1;
