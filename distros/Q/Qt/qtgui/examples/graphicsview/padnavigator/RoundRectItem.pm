package RoundRectItemObject;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Object );
use QtCore4::signals
    activated => [];
use QtCore4::slots
    updateValue => ['qreal'];

sub NEW {
    my ($class, $roundRectItem) = @_;
    $class->SUPER::NEW();
    this->{roundRectItem} = $roundRectItem;
}

sub updateValue {
    this->{roundRectItem}->updateValue(@_);
}

package RoundRectItem;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::GraphicsRectItem );
use RoundRectItemObject;

sub brush() {
    return this->{brush};
}

sub pix() {
    return this->{pix};
}

sub timeLine() {
    return this->{timeLine};
}

sub lastVal() {
    return this->{lastVal};
}

sub opa() {
    return this->{opa};
}

sub proxyWidget() {
    return this->{proxyWidget};
}

sub object {
    return this->{object};
}

sub NEW
{
    my ($class, $rect, $brush, $embeddedWidget) = @_;
    $class->SUPER::NEW($rect);
    if ( $brush->isa('Qt::Brush') ) {
        this->{brush} = $brush;
    }
    else {
        this->{brush} = Qt::Brush($brush);
    }
    this->{timeline} = 75;
    this->{lastVal} = 0;
    this->{opa} = 1;
    this->{proxyWidget} = 0;
    this->{timeLine} = Qt::TimeLine();
    this->{object} = RoundRectItemObject(this);
    this->{object}->connect(timeLine, SIGNAL 'valueChanged(qreal)',
            this->{object}, SLOT 'updateValue(qreal)');
    
    if ($embeddedWidget) {
        this->{proxyWidget} = Qt::GraphicsProxyWidget(this);
        proxyWidget->setFocusPolicy(Qt::StrongFocus());
        proxyWidget->setWidget($embeddedWidget);
        proxyWidget->setGeometry(boundingRect()->adjusted(25, 25, -25, -25));
    }
}

sub paint
{
    my ($painter) = @_;
    my $x = $painter->worldTransform();

    my $unit = $x->map(Qt::LineF(0, 0, 1, 1));
    if ($unit->p1()->x() > $unit->p2()->x() || $unit->p1()->y() > $unit->p2()->y()) {
        if (proxyWidget && proxyWidget->isVisible()) {
            proxyWidget->hide();
            proxyWidget->setGeometry(rect());
        }
        return;
    }

    if (proxyWidget && !proxyWidget->isVisible()) {
        proxyWidget->show();
        proxyWidget->setFocus();
    }
    if (proxyWidget && proxyWidget->pos() != Qt::Point()) {
        proxyWidget->setGeometry(boundingRect()->adjusted(25, 25, -25, -25));
    }

    $painter->setOpacity(opacity());
    $painter->setPen(Qt::NoPen());
    $painter->setBrush(Qt::Brush(Qt::Color(0, 0, 0, 64)));
    $painter->drawRoundRect(rect()->translated(2, 2));

    if (!proxyWidget) {
        my $gradient = Qt::LinearGradient(rect()->topLeft(), rect()->bottomRight());
        my $col = brush->color();
        $gradient->setColorAt(0, $col);
        $gradient->setColorAt(1, $col->dark(int(200 + lastVal * 50)));
        $painter->setBrush(Qt::Brush($gradient));
    } else {
        $painter->setBrush(brush);
    }

    $painter->setPen(Qt::Pen(Qt::Brush(Qt::Color(Qt::black())), 1));
    $painter->drawRoundRect(rect());
    if (pix && !pix->isNull()) {
        $painter->scale(1.95, 1.95);
        $painter->drawPixmap(-(pix()->width()) / 2, -(pix->height()) / 2, pix);
    }
}

sub boundingRect
{
    my $penW = 0.5;
    my $shadowW = 2.0;
    return rect()->adjusted(-$penW, -$penW, $penW + $shadowW, $penW + $shadowW);
}

sub setPixmap
{
    my ($pixmap) = @_;
    this->{pix} = $pixmap;
    if (scene() && isVisible()) {
        update();
    }
}

sub opacity
{
    my $parent = parentItem() ? parentItem() : undef;
    return opa + ($parent ? $parent->opacity() : 0);
}

sub setOpacity
{
    my ($opacity) = @_;
    this->{opa} = $opacity;
    update();
}

sub keyPressEvent
{
    my ($event) = @_;
    if ($event->isAutoRepeat() || $event->key() != Qt::Key_Return()
        || (timeLine->state() == Qt::TimeLine::Running() && timeLine->direction() == Qt::TimeLine::Forward())) {
        this->SUPER::keyPressEvent($event);
        return;
    }

    timeLine->stop();
    timeLine->setDirection(Qt::TimeLine::Forward());
    timeLine->start();
    emit this->{object}->activated();
}

sub keyReleaseEvent
{
    my ($event) = @_;
    if ($event->key() != Qt::Key_Return()) {
        this->SUPER::keyReleaseEvent($event);
        return;
    }
    timeLine->stop();
    timeLine->setDirection(Qt::TimeLine::Backward());
    timeLine->start();
}

sub updateValue
{
    my ($value) = @_;
    this->{lastVal} = $value;
    if (!proxyWidget) {
        setTransform(Qt::Transform()->scale(1 - $value / 10.0, 1 - $value / 10.0));
    }
}

1;
