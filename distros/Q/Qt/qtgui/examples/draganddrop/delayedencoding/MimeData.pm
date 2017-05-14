package MimeData;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MimeData );

#[0]
use QtCore4::signals
    dataRequested => ['QString'];
#[0]

sub NEW {
    shift->SUPER::NEW();
}

#[0]
sub formats {
    return ['image/png'];
}
#[0]

#[1]
sub retrieveData {
    my ($mimeType, $type) = @_;
    emit dataRequested($mimeType);

    return Qt::Variant(this->SUPER::retrieveData($mimeType, $type));
}
#[1]

1;
