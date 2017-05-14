package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use CircleWidget;

sub text() {
    return this->{text};
}

sub aliasedLabel() {
    return this->{aliasedLabel};
}

sub antialiasedLabel() {
    return this->{antialiasedLabel};
}

sub intLabel() {
    return this->{intLabel};
}

sub floatLabel() {
    return this->{floatLabel};
}

sub circleWidgets() {
    return this->{circleWidgets};
}
# [0]

# [0]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();

    this->{aliasedLabel} = this->createLabel(this->tr('Aliased'));
    this->{antialiasedLabel} = this->createLabel(this->tr('Antialiased'));
    this->{intLabel} = this->createLabel(this->tr('Int'));
    this->{floatLabel} = this->createLabel(this->tr('Float'));
    this->{circleWidgets} = [];

    my $layout = Qt::GridLayout();
    $layout->addWidget(this->aliasedLabel, 0, 1);
    $layout->addWidget(this->antialiasedLabel, 0, 2);
    $layout->addWidget(this->intLabel, 1, 0);
    $layout->addWidget(this->floatLabel, 2, 0);
# [0]

# [1]
    my $timer = Qt::Timer(this);

    for (my $i = 0; $i < 2; ++$i) {
        for (my $j = 0; $j < 2; ++$j) {
            this->circleWidgets->[$i]->[$j] = CircleWidget();
            this->circleWidgets->[$i]->[$j]->setAntialiased($j != 0);
            this->circleWidgets->[$i]->[$j]->setFloatBased($i != 0);

            this->connect($timer, SIGNAL 'timeout()',
                    this->circleWidgets->[$i]->[$j], SLOT 'nextAnimationFrame()');

            $layout->addWidget(this->circleWidgets->[$i]->[$j], $i + 1, $j + 1);
        }
    }
# [1] //! [2]
    $timer->start(100);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('Concentric Circles'));
}
# [2]

# [3]
sub createLabel
{
    my ($text) = @_;
    my $label = Qt::Label($text);
    $label->setAlignment(Qt::AlignCenter());
    $label->setMargin(2);
    $label->setFrameStyle(Qt::Frame::Box() | Qt::Frame::Sunken());
    return $label;
}
# [3]

1;
