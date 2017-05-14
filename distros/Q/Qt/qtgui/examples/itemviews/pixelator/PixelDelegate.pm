package PixelDelegate;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use List::Util qw( min );

use constant ItemSize => 256;

# [0]
use QtCore4::isa qw( Qt::AbstractItemDelegate );
use QtCore4::slots
    setPixelSize => ['int'];

sub pixelSize() {
    return this->{pixelSize};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{pixelSize} = 12;
}
# [0]

our @MYSTYLES = qw(State_None State_Active State_AutoRaise State_Children State_DownArrow State_Editing State_Enabled State_HasFocus State_Horizontal State_KeyboardFocusChange State_MouseOver State_NoChange State_Off State_On State_Raised State_ReadOnly State_Selected State_Item State_Open State_Sibling State_Sunken State_UpArrow State_Mini State_Small);

# [1]
sub paint
{
    my ($painter, $option, $index) = @_;
# [2]
    #print join "\n",
        #map{ $MYSTYLES[$_] } grep{ $_ } map{
            #my $opt = $MYSTYLES[$_];
            #my $state = $option->state();
            #my $eval = eval("Qt::Style::$opt()");
            #$_ if ${$state & $eval}
        #} 0..@MYSTYLES-1;
    if (${$option->state & Qt::Style::State_Selected()}) {
        $painter->fillRect($option->rect, $option->palette->highlight());
    }
# [1]

# [3]
    my $size = min($option->rect->width(), $option->rect->height());
# [3] //! [4]
    my $brightness = $index->model()->data($index, Qt::DisplayRole())->toInt();
    my $radius = ($size/2.0) - ($brightness/255.0 * $size/2.0);
    if ($radius == 0.0) {
        return;
    }
# [4]

# [5]
    $painter->save();
# [5] //! [6]
    $painter->setRenderHint(Qt::Painter::Antialiasing(), 1);
# [6] //! [7]
    $painter->setPen(Qt::NoPen());
# [7] //! [8]
    if (${$option->state & Qt::Style::State_Selected()}) {
# [8] //! [9]
        $painter->setBrush($option->palette->highlightedText());
    }
    else {
# [2]
        $painter->setBrush(Qt::Brush(Qt::Color(Qt::black())));
    }
# [9]

# [10]
    $painter->drawEllipse(Qt::RectF($option->rect->x() + $option->rect->width()/2 - $radius,
                                $option->rect->y() + $option->rect->height()/2 - $radius,
                                2*$radius, 2*$radius));
    $painter->restore();
}
# [10]

# [11]
sub sizeHint
{
    return Qt::Size(pixelSize, pixelSize);
}
# [11]

# [12]
sub setPixelSize
{
    my ($size) = @_;
    this->{pixelSize} = $size;
}
# [12]

1;
