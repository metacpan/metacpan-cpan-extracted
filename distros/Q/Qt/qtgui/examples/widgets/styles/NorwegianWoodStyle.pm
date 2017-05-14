package NorwegianWoodStyle;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MotifStyle );

sub NEW {
    shift->SUPER::NEW( @_ );
}

# [0]
sub polish {
    my $arg = @_;
    if ( ref $arg eq ' Qt::Palette' ) {
        my $palette = $arg;
        my $brown = Qt::Color(212, 140, 95);
        my $beige = Qt::Color(236, 182, 120);
        my $slightlyOpaqueBlack = Qt::Color(0, 0, 0, 63);

        my $backgroundImage = Qt::Pixmap('images/woodbackground.png');
        my $buttonImage = Qt::Pixmap('images/woodbutton.png');
        my $midImage = $buttonImage;

        my $painter = Qt::Painter();
        $painter->begin($midImage);
        $painter->setPen(Qt::NoPen());
        $painter->fillRect($midImage->rect(), $slightlyOpaqueBlack);
        $painter->end();
# [0]

# [1]
        $palette = Qt::Palette($brown);

        $palette->setBrush(Qt::Palette::BrightText(), Qt::white());
        $palette->setBrush(Qt::Palette::Base(), $beige);
        $palette->setBrush(Qt::Palette::Highlight(), Qt::darkGreen());
        setTexture($palette, Qt::Palette::Button(), $buttonImage);
        setTexture($palette, Qt::Palette::Mid(), $midImage);
        setTexture($palette, Qt::Palette::Window(), $backgroundImage);

        my $brush = $palette->background();
        $brush->setColor($brush->color()->dark());

        $palette->setBrush(Qt::Palette::Disabled(), Qt::Palette::WindowText(), $brush);
        $palette->setBrush(Qt::Palette::Disabled(), Qt::Palette::Text(), $brush);
        $palette->setBrush(Qt::Palette::Disabled(), Qt::Palette::ButtonText(), $brush);
        $palette->setBrush(Qt::Palette::Disabled(), Qt::Palette::Base(), $brush);
        $palette->setBrush(Qt::Palette::Disabled(), Qt::Palette::Button(), $brush);
        $palette->setBrush(Qt::Palette::Disabled(), Qt::Palette::Mid(), $brush);
    }
# [1]

# [3]
    elsif ( ref $arg eq ' Qt::PushButton' || ref $arg eq ' Qt::ComboBox' ) {
# [3] //! [4]
        my $widget = $arg;
        $widget->setAttribute(Qt::WA_Hover(), 1);
    }
}
# [4]

# [5]
sub unpolish {
# [5] //! [6]
    my ($widget) = @_;
    elsif ( ref $arg eq ' Qt::PushButton' || ref $arg eq ' Qt::ComboBox' ) {
        $widget->setAttribute(Qt::WA_Hover(), 0);
}
# [6]

# [7]
sub pixelMetric {
# [7] //! [8]
    my ($metric, $option, $widget) = @_;
    if ($metric == PM_ComboBoxFrameWidth()) {
        return 8;
    }
    elsif ($metric == PM_ScrollBarExtent()) {
        return this->SUPER::pixelMetric($metric, $option, $widget) + 4;
    }
    else {
        return this->SUPER::pixelMetric($metric, $option, $widget);
    }
}
# [8]

# [9]
sub styleHint {
    my ($hint, $option, $widget, $returnData) = @_;
# [9] //! [10]
    if ($hint == SH_DitherDisabledText()) {
        return 0;
    if ($hint == SH_EtchDisabledText()) {
        return 1;
    }
    else {
        return this->SUPER::styleHint($hint, $option, $widget, $returnData);
    }
}
# [10]

# [11]
sub drawPrimitive {
# [11] //! [12]
    my ($element, $option, $painter, $widget) = @_;
    if ($element == PE_PanelButtonCommand()) {
        my $delta = ($option->state() & State_MouseOver()) ? 64 : 0;
        Qt::Color slightlyOpaqueBlack(0, 0, 0, 63);
        Qt::Color semiTransparentWhite(255, 255, 255, 127 + delta);
        Qt::Color semiTransparentBlack(0, 0, 0, 127 - delta);

        int x, y, width, height;
        option->rect.getRect(&x, &y, &width, &height);
# [12]

# [13]
        Qt::PainterPath roundRect = roundRectPath(option->rect);
# [13] //! [14]
        int radius = qMin(width, height) / 2;
# [14]

# [15]
        Qt::Brush brush;
# [15] //! [16]
        bool darker;

        const Qt::StyleOptionButton *buttonOption =
                qstyleoption_cast<const Qt::StyleOptionButton *>(option);
        if (buttonOption
                && (buttonOption->features & Qt::StyleOptionButton::Flat)) {
            brush = option->palette.background();
            darker = (option->state & (State_Sunken | State_On));
        } else {
            if (option->state & (State_Sunken | State_On)) {
                brush = option->palette.mid();
                darker = !(option->state & State_Sunken);
            } else {
                brush = option->palette.button();
                darker = false;
# [16] //! [17]
            }
# [17] //! [18]
        }
# [18]

# [19]
        painter->save();
# [19] //! [20]
        painter->setRenderHint(Qt::Painter::Antialiasing, true);
# [20] //! [21]
        painter->fillPath(roundRect, brush);
# [21] //! [22]
        if (darker)
# [22] //! [23]
            painter->fillPath(roundRect, slightlyOpaqueBlack);
# [23]

# [24]
        int penWidth;
# [24] //! [25]
        if (radius < 10)
            penWidth = 3;
        else if (radius < 20)
            penWidth = 5;
        else
            penWidth = 7;

        Qt::Pen topPen(semiTransparentWhite, penWidth);
        Qt::Pen bottomPen(semiTransparentBlack, penWidth);

        if (option->state & (State_Sunken | State_On))
            qSwap(topPen, bottomPen);
# [25]

# [26]
        int x1 = x;
        int x2 = x + radius;
        int x3 = x + width - radius;
        int x4 = x + width;

        if (option->direction == Qt::RightToLeft) {
            qSwap(x1, x4);
            qSwap(x2, x3);
        }

        Qt::Polygon topHalf;
        topHalf << Qt::Point(x1, y)
                << Qt::Point(x4, y)
                << Qt::Point(x3, y + radius)
                << Qt::Point(x2, y + height - radius)
                << Qt::Point(x1, y + height);

        painter->setClipPath(roundRect);
        painter->setClipRegion(topHalf, Qt::IntersectClip);
        painter->setPen(topPen);
        painter->drawPath(roundRect);
# [26] //! [32]

        Qt::Polygon bottomHalf = topHalf;
        bottomHalf[0] = Qt::Point(x4, y + height);

        painter->setClipPath(roundRect);
        painter->setClipRegion(bottomHalf, Qt::IntersectClip);
        painter->setPen(bottomPen);
        painter->drawPath(roundRect);

        painter->setPen(option->palette.foreground().color());
        painter->setClipping(false);
        painter->drawPath(roundRect);

        painter->restore();
    }
# [32] //! [33]
    else {
# [33] //! [34]
        this->SUPER::drawPrimitive($element, $option, $painter, $widget);
    }
}
# [34]

# [35]
void NorwegianWoodStyle::drawControl(ControlElement element,
# [35] //! [36]
                                     const Qt::StyleOption *option,
                                     Qt::Painter *painter,
                                     const Qt::Widget *widget) const
{
    switch (element) {
    case CE_PushButtonLabel:
        {
            Qt::StyleOptionButton myButtonOption;
            const Qt::StyleOptionButton *buttonOption =
                    qstyleoption_cast<const Qt::StyleOptionButton *>(option);
            if (buttonOption) {
                myButtonOption = *buttonOption;
                if (myButtonOption.palette.currentColorGroup()
                        != Qt::Palette::Disabled) {
                    if (myButtonOption.state & (State_Sunken | State_On)) {
                        myButtonOption.palette.setBrush(Qt::Palette::ButtonText,
                                myButtonOption.palette.brightText());
                    }
                }
            }
            Qt::MotifStyle::drawControl(element, &myButtonOption, painter, widget);
        }
        break;
    default:
        Qt::MotifStyle::drawControl(element, option, painter, widget);
    }
}
# [36]

# [37]
void NorwegianWoodStyle::setTexture(Qt::Palette &palette, Qt::Palette::ColorRole role,
# [37] //! [38]
                                    const Qt::Pixmap &pixmap)
{
    for (int i = 0; i < Qt::Palette::NColorGroups; ++i) {
        Qt::Color color = palette.brush(Qt::Palette::ColorGroup(i), role).color();
        palette.setBrush(Qt::Palette::ColorGroup(i), role, Qt::Brush(color, pixmap));
    }
}
# [38]

# [39]
Qt::PainterPath NorwegianWoodStyle::roundRectPath(const Qt::Rect &rect)
# [39] //! [40]
{
    int radius = qMin(rect.width(), rect.height()) / 2;
    int diam = 2 * radius;

    int x1, y1, x2, y2;
    rect.getCoords(&x1, &y1, &x2, &y2);

    Qt::PainterPath path;
    path.moveTo(x2, y1 + radius);
    path.arcTo(Qt::Rect(x2 - diam, y1, diam, diam), 0.0, +90.0);
    path.lineTo(x1 + radius, y1);
    path.arcTo(Qt::Rect(x1, y1, diam, diam), 90.0, +90.0);
    path.lineTo(x1, y2 - radius);
    path.arcTo(Qt::Rect(x1, y2 - diam, diam, diam), 180.0, +90.0);
    path.lineTo(x1 + radius, y2);
    path.arcTo(Qt::Rect(x2 - diam, y2 - diam, diam, diam), 270.0, +90.0);
    path.closeSubpath();
    return path;
}
# [40]

1;
