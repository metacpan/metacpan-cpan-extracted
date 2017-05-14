package DragLabel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Label );
sub m_labelText() {
    return this->{m_labelText};
}

# [0]
sub NEW
{
    my ($class, $text, $parent) = @_;
    $class->SUPER::NEW($parent);

    my $metric = Qt::FontMetrics(this->font());
    my $size = $metric->size(Qt::TextSingleLine(), $text);

    my $image = Qt::Image($size->width() + 12, $size->height() + 12,
                 Qt::Image::Format_ARGB32_Premultiplied());
    $image->fill(0x00000000);

    my $font = Qt::Font();
    $font->setStyleStrategy(Qt::Font::ForceOutline());
# [0]

# [1]
    my $gradient = Qt::LinearGradient(0, 0, 0, $image->height()-1);
    $gradient->setColorAt(0.0, Qt::Color(Qt::white()));
    $gradient->setColorAt(0.2, Qt::Color(200, 200, 255));
    $gradient->setColorAt(0.8, Qt::Color(200, 200, 255));
    $gradient->setColorAt(1.0, Qt::Color(127, 127, 200));

    my $painter = Qt::Painter();
    $painter->begin($image);
    $painter->setRenderHint(Qt::Painter::Antialiasing());
    $painter->setBrush(Qt::Brush($gradient));
    $painter->drawRoundedRect(Qt::RectF(0.5, 0.5, $image->width()-1, $image->height()-1),
                            25, 25, Qt::RelativeSize());

    $painter->setFont($font);
    $painter->setBrush(Qt::Brush(Qt::black()));
    $painter->drawText(Qt::Rect(Qt::Point(6, 6), $size), Qt::AlignCenter(), $text);
    $painter->end();
# [1]

# [2]
    this->setPixmap(Qt::Pixmap::fromImage($image));
    this->{m_labelText} = $text;
}
# [2]

sub labelText
{
    return this->{m_labelText};
}

1;
