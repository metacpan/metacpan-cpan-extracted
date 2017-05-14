package GraphWidget;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::GraphicsView );
use Edge;
use Node;
use constant { RAND_MAX => 2147483647 };

sub timerId() {
    return this->{timerId};
}

sub centerNode() {
    return this->{centerNode};
}

sub NEW
{
    my($class) = @_;
    $class->SUPER::NEW();
    this->{timerId} = 0;
    my $scene = Qt::GraphicsScene(this);
    $scene->setItemIndexMethod(Qt::GraphicsScene::NoIndex());
    $scene->setSceneRect(-200, -200, 400, 400);
    this->setScene($scene);
    this->setCacheMode(Qt::GraphicsView::CacheBackground());
    this->setViewportUpdateMode(Qt::GraphicsView::BoundingRectViewportUpdate());
    this->setRenderHint(Qt::Painter::Antialiasing());
    this->setTransformationAnchor(Qt::GraphicsView::AnchorUnderMouse());
    this->setResizeAnchor(Qt::GraphicsView::AnchorViewCenter());

    my $node1 = Node(this);
    my $node2 = Node(this);
    my $node3 = Node(this);
    my $node4 = Node(this);
    this->{centerNode} = Node(this);
    my $node6 = Node(this);
    my $node7 = Node(this);
    my $node8 = Node(this);
    my $node9 = Node(this);
    $scene->addItem($node1);
    $scene->addItem($node2);
    $scene->addItem($node3);
    $scene->addItem($node4);
    $scene->addItem(this->centerNode);
    $scene->addItem($node6);
    $scene->addItem($node7);
    $scene->addItem($node8);
    $scene->addItem($node9);
    $scene->addItem(Edge($node1, $node2));
    $scene->addItem(Edge($node2, $node3));
    $scene->addItem(Edge($node2, this->centerNode));
    $scene->addItem(Edge($node3, $node6));
    $scene->addItem(Edge($node4, $node1));
    $scene->addItem(Edge($node4, this->centerNode));
    $scene->addItem(Edge(this->centerNode, $node6));
    $scene->addItem(Edge(this->centerNode, $node8));
    $scene->addItem(Edge($node6, $node9));
    $scene->addItem(Edge($node7, $node4));
    $scene->addItem(Edge($node8, $node7));
    $scene->addItem(Edge($node9, $node8));

    $node1->setPos(-50, -50);
    $node2->setPos(0, -50);
    $node3->setPos(50, -50);
    $node4->setPos(-50, 0);
    this->centerNode->setPos(0, 0);
    $node6->setPos(50, 0);
    $node7->setPos(-50, 50);
    $node8->setPos(0, 50);
    $node9->setPos(50, 50);

    this->scale(0.8, 0.8);
    this->setMinimumSize(400, 400);
    this->setWindowTitle(this->tr('Elastic Nodes'));
}

sub itemMoved
{
    if (!this->{timerId}) {
        this->{timerId} = this->startTimer(1000 / 25);
    }
}

sub keyPressEvent
{
    my ($event) = @_;
    if ($event->key() == Qt::Key_Up()) {
        this->centerNode->moveBy(0, -20);
    }
    elsif ($event->key() == Qt::Key_Down()) {
        this->centerNode->moveBy(0, 20);
    }
    elsif ($event->key() == Qt::Key_Left()) {
        this->centerNode->moveBy(-20, 0);
    }
    elsif ($event->key() == Qt::Key_Right()) {
        this->centerNode->moveBy(20, 0);
    }
    elsif ($event->key() == Qt::Key_Plus()) {
        this->scaleView(1.2);
    }
    elsif ($event->key() == Qt::Key_Minus()) {
        this->scaleView(1 / 1.2);
    }
    elsif ($event->key() == Qt::Key_Space() ||
        $event->key() == Qt::Key_Enter()) {
        foreach my $item (@{this->scene()->items()}) {
            if ($item->isa('Node')) {
                $item->setPos(-150 + rand(RAND_MAX) % 300, -150 + rand(RAND_MAX) % 300);
            }
        }
    }
    else {
        this->SUPER::keyPressEvent($event);
    }
}

sub timerEvent
{
    my @nodes;
    foreach my $item (@{this->scene()->items()}) {
        if ($item->isa('Node')){
            push @nodes, $item;
        }
    }

    foreach my $node (@nodes) {
        $node->calculateForces();
    }

    my $itemsMoved = 0;
    foreach my $node (@nodes) {
        if ($node->advance()) {
            $itemsMoved = 1;
        }
    }

    if (!$itemsMoved) {
        this->killTimer(this->timerId);
        this->{timerId} = 0;
    }
}

sub wheelEvent
{
    my ($event) = @_;
    this->scaleView(2**(-($event->delta()) / 240.0));
}

sub drawBackground
{
    my ($painter, $rect) = @_;

    # Shadow
    my $sceneRect = this->sceneRect();
    my $rightShadow = Qt::RectF($sceneRect->right(), $sceneRect->top() + 5, 5, $sceneRect->height());
    my $bottomShadow = Qt::RectF($sceneRect->left() + 5, $sceneRect->bottom(), $sceneRect->width(), 5);
    if ($rightShadow->intersects($rect) || $rightShadow->contains($rect)) {
        $painter->fillRect($rightShadow, Qt::darkGray());
    }
    if ($bottomShadow->intersects($rect) || $bottomShadow->contains($rect)) {
        $painter->fillRect($bottomShadow, Qt::darkGray());
    }

    # Fill
    my $gradient = Qt::LinearGradient($sceneRect->topLeft(), $sceneRect->bottomRight());
    $gradient->setColorAt(0, Qt::Color(Qt::white()));
    $gradient->setColorAt(1, Qt::Color(Qt::lightGray()));
    $painter->fillRect($rect->intersect($sceneRect), Qt::Brush($gradient));
    $painter->setBrush(Qt::NoBrush());
    $painter->drawRect($sceneRect);

    # Text
    my $textRect = Qt::RectF($sceneRect->left() + 4, $sceneRect->top() + 4,
                    $sceneRect->width() - 4, $sceneRect->height() - 4);
    my $message = this->tr('Click and drag the nodes around, and zoom with the mouse ' .
                       'wheel or the \'+\' and \'-\' keys');

    my $font = $painter->font();
    $font->setBold(1);
    $font->setPointSize(14);
    $painter->setFont($font);
    $painter->setPen(Qt::Color(Qt::lightGray()));
    $painter->drawText($textRect->translated(2, 2), $message);
    $painter->setPen(Qt::Color(Qt::black()));
    $painter->drawText($textRect, $message);
}

sub scaleView
{
    my ($scaleFactor) = @_;
    my $factor = this->matrix()->scale($scaleFactor, $scaleFactor)->mapRect(Qt::RectF(0, 0, 1, 1))->width();
    if ($factor < 0.07 || $factor > 100) {
        return;
    }

    this->scale($scaleFactor, $scaleFactor);
}

1;
