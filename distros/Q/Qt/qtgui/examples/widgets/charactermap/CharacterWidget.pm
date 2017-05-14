package CharacterWidget;

use strict;
use warnings;

use List::Util qw( max );
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

use QtCore4::slots
    updateFont => ['QFont'],
    updateSize => ['QString'],
    updateStyle => ['QString'],
    updateFontMerging => ['bool'];

use QtCore4::signals
    characterSelected => ['QString'];

sub displayFont() {
    return this->{displayFont};
}

sub columns() {
    return this->{columns};
}

sub lastKey() {
    return this->{lastKey};
}

sub squareSize() {
    return this->{squareSize};
}

sub setDisplayFont() {
    return this->{displayFont} = shift;
}

sub setColumns() {
    return this->{columns} = shift;
}

sub setLastKey() {
    return this->{lastKey} = shift;
}

sub setSquareSize() {
    return this->{squareSize} = shift;
}

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setSquareSize( 24 );
    this->setColumns( 16 );
    this->setLastKey( -1 );
    this->setDisplayFont( Qt::Font() );
    this->setMouseTracking(1);
}
# [0]

# [1]
sub updateFont {
    my ($font) = @_;
    this->displayFont->setFamily($font->family());
    this->setSquareSize( max(24, Qt::FontMetrics(this->displayFont)->xHeight() * 3) );
    this->adjustSize();
    this->update();
}
# [1]

# [2]
sub updateSize {
    my ($fontSize) = @_;
    this->displayFont->setPointSize($fontSize);
    this->setSquareSize( max(24, Qt::FontMetrics(displayFont)->xHeight() * 3) );
    this->adjustSize();
    this->update();
}
# [2]

sub updateStyle {
    my ($fontStyle) = @_;
    my $fontDatabase = Qt::FontDatabase();
    my $oldStrategy = this->displayFont->styleStrategy();
    this->setDisplayFont( $fontDatabase->font(this->displayFont->family(), $fontStyle, this->displayFont->pointSize()) );
    this->displayFont->setStyleStrategy($oldStrategy);
    this->setSquareSize( max(24, Qt::FontMetrics(displayFont)->xHeight() * 3) );
    this->adjustSize();
    this->update();
}

sub updateFontMerging {
    my ($enable) = @_;
    if ($enable) {
        this->displayFont->setStyleStrategy(Qt::Font::PreferDefault());
    }
    else {
        this->displayFont->setStyleStrategy(Qt::Font::NoFontMerging());
    }
    this->adjustSize();
    this->update();
}

# [3]
sub sizeHint {
    return Qt::Size(this->columns*this->squareSize, (65536/this->columns)*this->squareSize);
}
# [3]

# [4]
sub mouseMoveEvent {
    my ($event) = @_;
    my $widgetPosition = this->mapFromGlobal($event->globalPos());
    my $key = sprintf '%d', (sprintf '%d', $widgetPosition->y()/this->squareSize)*this->columns + $widgetPosition->x()/this->squareSize;

    my $char = chr($key);
    utf8::upgrade($char);
    my $text = sprintf( "<p>Character: <span style=\"font-size: 24pt; font-family: %s\">", this->displayFont->family() )
                  . $char
                  . "</span><p>Value: 0x"
                  . sprintf( '%x', $key );
    Qt::ToolTip::showText($event->globalPos(), $text, this);
}
# [4]

# [5]
sub mousePressEvent {
    my ($event) = @_;
    if ($event->button() == Qt::LeftButton()) {
        this->setLastKey( sprintf '%d', (sprintf '%d', $event->y()/this->squareSize)*this->columns + $event->x()/this->squareSize );
        if (Qt::Char(this->lastKey)->category() != Qt::Char::NoCategory()) {
            my $char = chr(this->lastKey);
            utf8::upgrade($char);
            emit this->characterSelected($char);
        }
        this->update();
    }
    else {
        this->SUPER::mousePressEvent($event);
    }
}
# [5]

# [6]
sub paintEvent {
    my ($event) = @_;
    my $squareSize = this->squareSize;
    my $painter = Qt::Painter(this);
    $painter->fillRect($event->rect(), Qt::Brush(Qt::white()));
    $painter->setFont(this->displayFont);
# [6]

# [7]
    my $redrawRect = $event->rect();
    my $beginRow = sprintf '%d', $redrawRect->top()/$squareSize;
    my $endRow = sprintf '%d', $redrawRect->bottom()/$squareSize;
    my $beginColumn = sprintf '%d', $redrawRect->left()/$squareSize;
    my $endColumn = sprintf '%d', $redrawRect->right()/$squareSize;
# [7]

# [8]
    $painter->setPen(Qt::Color(Qt::gray()));
    for (my $row = $beginRow; $row <= $endRow; ++$row) {
        for (my $column = $beginColumn; $column <= $endColumn; ++$column) {
            $painter->drawRect($column*$squareSize, $row*$squareSize, $squareSize, $squareSize);
        }
# [8] //! [9]
    }
# [9]

# [10]
    my $fontMetrics = Qt::FontMetrics(this->displayFont);
    $painter->setPen(Qt::Color(Qt::black()));
    for (my $row = $beginRow; $row <= $endRow; ++$row) {

        for (my $column = $beginColumn; $column <= $endColumn; ++$column) {

            my $key = $row*this->columns + $column;
            $painter->setClipRect($column*$squareSize, $row*$squareSize, $squareSize, $squareSize);

            if ($key == this->lastKey) {
                $painter->fillRect($column*$squareSize + 1, $row*$squareSize + 1, $squareSize, $squareSize, Qt::Brush(Qt::red()));
            }

            my $char = chr($key);
            utf8::upgrade($char);
            $painter->drawText($column*$squareSize + ($squareSize / 2) - $fontMetrics->width(Qt::Char(Qt::Int($key)))/2,
                             $row*$squareSize + 4 + $fontMetrics->ascent(),
                             $char);
        }
    }
    $painter->end();
}
# [10]

1;
