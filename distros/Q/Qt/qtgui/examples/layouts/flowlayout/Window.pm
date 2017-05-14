package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
# [0]
use FlowLayout;

# [1]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    my $flowLayout = FlowLayout();

    $flowLayout->addWidget(Qt::PushButton(this->tr('Short')));
    $flowLayout->addWidget(Qt::PushButton(this->tr('Longer')));
    $flowLayout->addWidget(Qt::PushButton(this->tr('Different text')));
    $flowLayout->addWidget(Qt::PushButton(this->tr('More text')));
    $flowLayout->addWidget(Qt::PushButton(this->tr('Even longer button text')));
    this->setLayout($flowLayout);

    this->setWindowTitle(this->tr('Flow Layout'));
}
# [1]

1;
