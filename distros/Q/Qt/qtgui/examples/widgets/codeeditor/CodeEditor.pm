package CodeEditor;

use strict;
use warnings;

use List::Util qw( max );
use QtCore4;
use QtGui4;

#[codeeditordefinition]

use QtCore4::isa qw( Qt::PlainTextEdit );
use QtCore4::slots
    updateLineNumberAreaWidth => ['int'],
    highlightCurrentLine => [],
    updateLineNumberArea => ['const QRect &', 'int'];

sub lineNumberArea() {
    return this->{lineNumberArea};
}

sub setLineNumberArea() {
    return this->{lineNumberArea} = shift;
}

#[codeeditordefinition]
#[extraarea]

package LineNumberArea;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

sub codeEditor() {
    return this->{codeEditor};
}

sub setCodeEditor() {
    return this->{codeEditor} = shift;
}

sub NEW {
    my ( $class, $editor ) = @_;
    $class->SUPER::NEW( $editor );
    this->setCodeEditor( $editor );
}

sub sizeHint {
    return Qt::Size(this->codeEditor->lineNumberAreaWidth(), 0);
}

sub paintEvent {
    my ($event) = @_;
    this->codeEditor->lineNumberAreaPaintEvent($event);
}

1;

#[extraarea]

package CodeEditor;

use LineNumberArea;

#[constructor]

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW( $parent );

    this->setLineNumberArea( LineNumberArea(this) );

    this->connect(this, SIGNAL 'blockCountChanged(int)', this, SLOT 'updateLineNumberAreaWidth(int)');
    this->connect(this, SIGNAL 'updateRequest(const QRect &, int)', this, SLOT 'updateLineNumberArea(const QRect &, int)');
    this->connect(this, SIGNAL 'cursorPositionChanged()', this, SLOT 'highlightCurrentLine()');

    this->updateLineNumberAreaWidth(0);
    this->highlightCurrentLine();
}

#[constructor]

#[extraAreaWidth]

sub lineNumberAreaWidth {
    my $digits = 1;
    my $max = max(1, this->blockCount());
    while ($max >= 10) {
        $max /= 10;
        ++$digits;
    }

    my $space = 3 + this->fontMetrics()->width(Qt::Char(Qt::Int(9))) * $digits;

    return $space;
}

#[extraAreaWidth]

#[slotUpdateExtraAreaWidth]

sub updateLineNumberAreaWidth { 
    this->setViewportMargins(this->lineNumberAreaWidth(), 0, 0, 0);
}

#[slotUpdateExtraAreaWidth]

#[slotUpdateRequest]

sub updateLineNumberArea {
    my ($rect, $dy) = @_;
    if ($dy) {
        this->lineNumberArea->scroll(0, $dy);
    }
    else {
        this->lineNumberArea->update(0, $rect->y(), this->lineNumberArea->width(), $rect->height());
    }

    if ($rect->contains(this->viewport()->rect())) {
        this->updateLineNumberAreaWidth(0);
    }
}

#[slotUpdateRequest]

#[resizeEvent]

sub resizeEvent {
    my ($e) = @_;
    this->SUPER::resizeEvent($e);

    my $cr = this->contentsRect();
    this->lineNumberArea->setGeometry(Qt::Rect($cr->left(), $cr->top(), this->lineNumberAreaWidth(), $cr->height()));
}

#[resizeEvent]

#[cursorPositionChanged]

sub highlightCurrentLine {
    my $extraSelections = [];

    if (!this->isReadOnly()) {
        my $selection = Qt::TextEdit::ExtraSelection();
        
        my $lineColor = Qt::Color(Qt::yellow())->lighter(160);

        $selection->format->setBackground( Qt::Brush( $lineColor ) );
        $selection->format->setProperty(Qt::TextFormat::FullWidthSelection(), Qt::Variant(Qt::Bool(1)));
        $selection->setCursor( this->textCursor() );
        $selection->cursor->clearSelection();
        push @{$extraSelections}, $selection;
    }

    this->setExtraSelections($extraSelections);
}

#[cursorPositionChanged]

#[extraAreaPaintEvent_0]

sub lineNumberAreaPaintEvent {
    my ($event) = @_;
    my $painter = Qt::Painter(this->lineNumberArea);
    $painter->fillRect($event->rect(), Qt::Brush(Qt::Color(Qt::lightGray())));

#[extraAreaPaintEvent_0]

#[extraAreaPaintEvent_1]
    my $block = this->firstVisibleBlock();
    my $blockNumber = $block->blockNumber();
    my $top = int this->blockBoundingGeometry($block)->translated(this->contentOffset())->top();
    my $bottom = $top + int this->blockBoundingRect($block)->height();
#[extraAreaPaintEvent_1]

#[extraAreaPaintEvent_2]
    while ($block->isValid() && $top <= $event->rect()->bottom()) {
        if ($block->isVisible() && $bottom >= $event->rect()->top()) {
            my $number = $blockNumber + 1;
            $painter->setPen(Qt::Color(Qt::black()));
            $painter->drawText(0, $top, this->lineNumberArea->width(), this->fontMetrics()->height(),
                             Qt::AlignRight(), $number);
        }

        $block = $block->next();
        $top = $bottom;
        $bottom = $top + int this->blockBoundingRect($block)->height();
        ++$blockNumber;
    }

    $painter->end();
}
#[extraAreaPaintEvent_2]

