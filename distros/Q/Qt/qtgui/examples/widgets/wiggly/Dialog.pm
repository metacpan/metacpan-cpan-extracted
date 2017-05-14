package Dialog;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );

use WigglyWidget;

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    my $wigglyWidget = WigglyWidget();
    my $lineEdit = Qt::LineEdit();

    my $layout = Qt::VBoxLayout();
    $layout->addWidget($wigglyWidget);
    $layout->addWidget($lineEdit);
    this->setLayout($layout);

    this->connect($lineEdit, SIGNAL 'textChanged(QString)',
            $wigglyWidget, SLOT 'setText(QString)');

    $lineEdit->setText(this->tr("Hello world!"));

    this->setWindowTitle(this->tr("Wiggly"));
    this->resize(360, 145);
}
# [0]

1;
