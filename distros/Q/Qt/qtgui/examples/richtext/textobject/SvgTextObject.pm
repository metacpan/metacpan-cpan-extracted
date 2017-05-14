package SvgTextObject;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Object, Qt::TextObjectInterface );
    #Q_INTERFACES(Qt::TextObjectInterface)

use constant SvgData => 1;

sub NEW {
    my ( $class ) = @_;
    $class->SUPER::NEW();
}

#[0]
sub intrinsicSize
{
    my $format = $_[2];
    my $bufferedImage = $format->property(SvgData)->value();
    my $size = $bufferedImage->size();
    
    if ($size->height() > 25) {
        $size *= 25.0 / $size->height();
    }

    return Qt::SizeF($size);
}
#[0]

#[1]
sub drawObject
{
    my ($painter, $rect, $format) = @_[0,1,4];
    my $bufferedImage = $format->property(SvgData)->value();

    $painter->drawImage($rect, $bufferedImage);
}
#[1]

1;
