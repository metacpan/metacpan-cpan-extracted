package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use DiagramItem;
use DiagramScene;
use DiagramTextItem;
# [0]
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    backgroundButtonGroupClicked => ['QAbstractButton *'],
    buttonGroupClicked => ['int'],
    deleteItem => [],
    pointerGroupClicked => ['int'],
    bringToFront => [],
    sendToBack => [],
    itemInserted => ['QGraphicsPolygonItem *'],
    textInserted => ['QGraphicsTextItem *'],
    currentFontChanged => ['const QFont &'],
    fontSizeChanged => ['const QString &'],
    sceneScaleChanged => ['const QString &'],
    textColorChanged => [],
    itemColorChanged => [],
    lineColorChanged => [],
    textButtonTriggered => [],
    fillButtonTriggered => [],
    lineButtonTriggered => [],
    handleFontChange => [],
    itemSelected => ['QGraphicsItem *'],
    about => [];

sub scene() {
    return this->{scene};
}

sub view() {
    return this->{view};
}

sub exitAction() {
    return this->{exitAction};
}

sub addAction() {
    return this->{addAction};
}

sub deleteAction() {
    return this->{deleteAction};
}

sub toFrontAction() {
    return this->{toFrontAction};
}

sub sendBackAction() {
    return this->{sendBackAction};
}

sub aboutAction() {
    return this->{aboutAction};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub itemMenu() {
    return this->{itemMenu};
}

sub aboutMenu() {
    return this->{aboutMenu};
}

sub textToolBar() {
    return this->{textToolBar};
}

sub editToolBar() {
    return this->{editToolBar};
}

sub colorToolBar() {
    return this->{colorToolBar};
}

sub pointerToolbar() {
    return this->{pointerToolbar};
}

sub sceneScaleCombo() {
    return this->{sceneScaleCombo};
}

sub itemColorCombo() {
    return this->{itemColorCombo};
}

sub textColorCombo() {
    return this->{textColorCombo};
}

sub fontSizeCombo() {
    return this->{fontSizeCombo};
}

sub fontCombo() {
    return this->{fontCombo};
}

sub toolBox() {
    return this->{toolBox};
}

sub buttonGroup() {
    return this->{buttonGroup};
}

sub pointerTypeGroup() {
    return this->{pointerTypeGroup};
}

sub backgroundButtonGroup() {
    return this->{backgroundButtonGroup};
}

sub fontColorToolButton() {
    return this->{fontColorToolButton};
}

sub fillColorToolButton() {
    return this->{fillColorToolButton};
}

sub lineColorToolButton() {
    return this->{lineColorToolButton};
}

sub boldAction() {
    return this->{boldAction};
}

sub underlineAction() {
    return this->{underlineAction};
}

sub italicAction() {
    return this->{italicAction};
}

sub textAction() {
    return this->{textAction};
}

sub fillAction() {
    return this->{fillAction};
}

sub lineAction() {
    return this->{lineAction};
}

my $InsertTextButton = 10;

# [0]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->createActions();
    this->createToolBox();
    this->createMenus();

    this->{scene} = DiagramScene(this->itemMenu);
    this->scene->setSceneRect(Qt::RectF(0, 0, 5000, 5000));
    this->connect(this->scene, SIGNAL 'itemInserted(QGraphicsPolygonItem*)',
            this, SLOT 'itemInserted(QGraphicsPolygonItem*)');
    this->connect(this->scene, SIGNAL 'textInserted(QGraphicsTextItem*)',
        this, SLOT 'textInserted(QGraphicsTextItem*)');
    this->connect(this->scene, SIGNAL 'itemSelected(QGraphicsItem*)',
        this, SLOT 'itemSelected(QGraphicsItem*)');
    this->createToolbars();

    my $layout = Qt::HBoxLayout();
    $layout->addWidget(this->toolBox);
    this->{view} = Qt::GraphicsView(this->scene);
    $layout->addWidget(this->view);

    my $widget = Qt::Widget();
    $widget->setLayout($layout);

    this->setCentralWidget($widget);
    this->setWindowTitle(this->tr('Diagramscene'));
    this->setUnifiedTitleAndToolBarOnMac(1);
}
# [0]

# [1]
sub backgroundButtonGroupClicked
{
    my ($button) = @_;
    my $buttons = this->backgroundButtonGroup->buttons();
    foreach my $myButton ( @{$buttons} ) {
        if ($myButton != $button) {
            $button->setChecked(0);
        }
    }
    my $text = $button->text();
    if ($text eq this->tr('Blue Grid')) {
        this->scene->setBackgroundBrush(Qt::Brush(Qt::Pixmap(':/images/background1.png')));
    }
    elsif ($text eq this->tr('White Grid')) {
        this->scene->setBackgroundBrush(Qt::Brush(Qt::Pixmap(':/images/background2.png')));
    }
    elsif ($text eq this->tr('Gray Grid')) {
        this->scene->setBackgroundBrush(Qt::Brush(Qt::Pixmap(':/images/background3.png')));
    }
    else {
        this->scene->setBackgroundBrush(Qt::Brush(Qt::Pixmap(':/images/background4.png')));
    }

    this->scene->update();
    this->view->update();
}
# [1]

# [2]
sub buttonGroupClicked
{
    my ($id) = @_;
    my $buttons = this->buttonGroup->buttons();
    foreach my $button ( @{$buttons} ) {
        if (this->buttonGroup->button($id) != $button) {
            $button->setChecked(0);
        }
    }
    if ($id == $InsertTextButton) {
        this->scene->setMode(DiagramScene::InsertText);
    } else {
        this->scene->setItemType($id);
        this->scene->setMode(DiagramScene::InsertItem);
    }
}
# [2]

# [3]
sub deleteItem
{
    foreach my $item ( @{scene->selectedItems()} ) {
        if ($item->type() == DiagramItem::Type) {
            $item->removeArrows();
        }
        this->scene->removeItem($item);
    }
}
# [3]

# [4]
sub pointerGroupClicked
{
    this->scene->setMode(this->pointerTypeGroup->checkedId());
}
# [4]

# [5]
sub bringToFront
{
    if (scalar @{this->scene->selectedItems()} < 0) {
        return;
    }

    my $selectedItem = this->scene->selectedItems()->[0];
    my $overlapItems = $selectedItem->collidingItems();

    my $zValue = 0;
    foreach my $item ( @{$overlapItems} ) {
        if ($item->zValue() >= $zValue &&
            $item->type() == DiagramItem::Type) {
            $zValue = $item->zValue() + 0.1;
        }
    }
    $selectedItem->setZValue($zValue);
}
# [5]

# [6]
sub sendToBack
{
    if (scalar @{this->scene->selectedItems()} < 0) {
        return;
    }

    my $selectedItem = this->scene->selectedItems()->[0];
    my $overlapItems = $selectedItem->collidingItems();

    my $zValue = 0;
    foreach my $item ( @{$overlapItems} ) {
        if ($item->zValue() <= $zValue &&
            $item->type() == DiagramItem::Type) {
            $zValue = $item->zValue() - 0.1;
        }
    }
    $selectedItem->setZValue($zValue);
}
# [6]

# [7]
sub itemInserted
{
    my ($item) = @_;
    this->pointerTypeGroup->button(DiagramScene::MoveItem)->setChecked(1);
    this->scene->setMode(this->pointerTypeGroup->checkedId());
    if ( $item->isa( 'DiagramItem' ) ) {
        this->buttonGroup->button($item->diagramType())->setChecked(0);
    }
}
# [7]

# [8]
sub textInserted
{
    this->buttonGroup->button($InsertTextButton)->setChecked(0);
    this->scene->setMode(this->pointerTypeGroup->checkedId());
}
# [8]

# [9]
sub currentFontChanged
{
    this->handleFontChange();
}
# [9]

# [10]
sub fontSizeChanged
{
    this->handleFontChange();
}
# [10]

# [11]
sub sceneScaleChanged
{
    my ($scale) = @_;
    my $newScale = $scale;
    $newScale =~ s/%//g;
    $newScale /= 100.0;
    my $oldMatrix = this->view->matrix();
    this->view->resetMatrix();
    this->view->translate($oldMatrix->dx(), $oldMatrix->dy());
    this->view->scale($newScale, $newScale);
}
# [11]

# [12]
sub textColorChanged
{
    this->{textAction} = this->sender();
    this->fontColorToolButton->setIcon(this->createColorToolButtonIcon(
                ':/images/textpointer.png',
                this->textAction->data()->value()));
    this->textButtonTriggered();
}
# [12]

# [13]
sub itemColorChanged
{
    this->{fillAction} = this->sender();
    this->fillColorToolButton->setIcon(this->createColorToolButtonIcon(
                 ':/images/floodfill.png',
                 this->fillAction->data()->value()));
    this->fillButtonTriggered();
}
# [13]

# [14]
sub lineColorChanged
{
    this->{lineAction} = this->sender();
    this->lineColorToolButton->setIcon(this->createColorToolButtonIcon(
                 ':/images/linecolor.png',
                 this->lineAction->data()->value()));;
    this->lineButtonTriggered();
}
# [14]

# [15]
sub textButtonTriggered
{
    this->scene->setTextColor(this->textAction->data()->value());
}
# [15]

# [16]
sub fillButtonTriggered
{
    this->scene->setItemColor(this->fillAction->data()->value());
}
# [16]

# [17]
sub lineButtonTriggered
{
    this->scene->setLineColor(this->lineAction->data()->value());
}
# [17]

# [18]
sub handleFontChange
{
    my $font = this->fontCombo->currentFont();
    $font->setPointSize(this->fontSizeCombo->currentText());
    $font->setWeight(this->boldAction->isChecked() ? Qt::Font::Bold() : Qt::Font::Normal());
    $font->setItalic(this->italicAction->isChecked());
    $font->setUnderline(this->underlineAction->isChecked());

    this->scene->setFont($font);
}
# [18]

# [19]
sub itemSelected
{
    my ($item) = @_;
    my $textItem = $item;

    my $font = $textItem->font();
    my $color = $textItem->defaultTextColor();
    this->fontCombo->setCurrentFont($font);
    this->fontSizeCombo->setEditText($font->pointSize());
    this->boldAction->setChecked($font->weight() == Qt::Font::Bold());
    this->italicAction->setChecked($font->italic());
    this->underlineAction->setChecked($font->underline());
}
# [19]

# [20]
sub about
{
    Qt::MessageBox::about(this, this->tr('About Diagram Scene'),
                       this->tr('The <b>Diagram Scene</b> example shows ' .
                          'use of the graphics framework.'));
}
# [20]

# [21]
sub createToolBox
{
    this->{buttonGroup} = Qt::ButtonGroup();
    this->buttonGroup->setExclusive(0);
    this->connect(this->buttonGroup, SIGNAL 'buttonClicked(int)',
            this, SLOT 'buttonGroupClicked(int)');
    my $layout = Qt::GridLayout();
    $layout->addWidget(this->createCellWidget(this->tr('Conditional'),
                               DiagramItem::Conditional), 0, 0);
    $layout->addWidget(this->createCellWidget(this->tr('Process'),
                      DiagramItem::Step),0, 1);
    $layout->addWidget(this->createCellWidget(this->tr('Input/Output'),
                      DiagramItem::Io), 1, 0);
# [21]

    my $textButton = Qt::ToolButton();
    $textButton->setCheckable(1);
    this->buttonGroup->addButton($textButton, $InsertTextButton);
    $textButton->setIcon(Qt::Icon(Qt::Pixmap(':/images/textpointer.png')
                        ->scaled(30, 30)));
    $textButton->setIconSize(Qt::Size(50, 50));
    my $textLayout = Qt::GridLayout();
    $textLayout->addWidget($textButton, 0, 0, Qt::AlignHCenter());
    $textLayout->addWidget(Qt::Label(this->tr('Text')), 1, 0, Qt::AlignCenter());
    my $textWidget = Qt::Widget();
    $textWidget->setLayout($textLayout);
    $layout->addWidget($textWidget, 1, 1);

    $layout->setRowStretch(3, 10);
    $layout->setColumnStretch(2, 10);

    my $itemWidget = Qt::Widget();
    $itemWidget->setLayout($layout);

    this->{backgroundButtonGroup} = Qt::ButtonGroup();
    this->connect(this->backgroundButtonGroup, SIGNAL 'buttonClicked(QAbstractButton*)',
            this, SLOT 'backgroundButtonGroupClicked(QAbstractButton*)');

    my $backgroundLayout = Qt::GridLayout();
    $backgroundLayout->addWidget(this->createBackgroundCellWidget(this->tr('Blue Grid'),
                ':/images/background1.png'), 0, 0);
    $backgroundLayout->addWidget(this->createBackgroundCellWidget(this->tr('White Grid'),
                ':/images/background2.png'), 0, 1);
    $backgroundLayout->addWidget(this->createBackgroundCellWidget(this->tr('Gray Grid'),
                    ':/images/background3.png'), 1, 0);
    $backgroundLayout->addWidget(this->createBackgroundCellWidget(this->tr('No Grid'),
                ':/images/background4.png'), 1, 1);

    $backgroundLayout->setRowStretch(2, 10);
    $backgroundLayout->setColumnStretch(2, 10);

    my $backgroundWidget = Qt::Widget();
    $backgroundWidget->setLayout($backgroundLayout);


# [22]
    this->{toolBox} = Qt::ToolBox();
    this->toolBox->setSizePolicy(Qt::SizePolicy(Qt::SizePolicy::Maximum(), Qt::SizePolicy::Ignored()));
    this->toolBox->setMinimumWidth($itemWidget->sizeHint()->width());
    this->toolBox->addItem($itemWidget, this->tr('Basic Flowchart Shapes'));
    this->toolBox->addItem($backgroundWidget, this->tr('Backgrounds'));
}
# [22]

# [23]
sub createActions
{
    this->{toFrontAction} = Qt::Action(Qt::Icon(':/images/bringtofront.png'),
                                this->tr('Bring to &Front'), this);
    this->toFrontAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+F')));
    this->toFrontAction->setStatusTip(this->tr('Bring item to front'));
    this->connect(this->toFrontAction, SIGNAL 'triggered()',
            this, SLOT 'bringToFront()');
# [23]

    this->{sendBackAction} = Qt::Action(Qt::Icon(':/images/sendtoback.png'),
                                 this->tr('Send to &Back'), this);
    this->sendBackAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+B')));
    this->sendBackAction->setStatusTip(this->tr('Send item to back'));
    this->connect(this->sendBackAction, SIGNAL 'triggered()',
        this, SLOT 'sendToBack()');

    this->{deleteAction} = Qt::Action(Qt::Icon(':/images/delete.png'),
                               this->tr('&Delete'), this);
    this->deleteAction->setShortcut(Qt::KeySequence(this->tr('Delete')));
    this->deleteAction->setStatusTip(this->tr('Delete item from diagram'));
    this->connect(this->deleteAction, SIGNAL 'triggered()',
        this, SLOT 'deleteItem()');

    this->{exitAction} = Qt::Action(this->tr('E&xit'), this);
    this->exitAction->setShortcuts(Qt::KeySequence::Quit());
    this->exitAction->setStatusTip(this->tr('Quit Scenediagram example'));
    this->connect(this->exitAction, SIGNAL 'triggered()', this, SLOT 'close()');

    this->{boldAction} = Qt::Action(this->tr('Bold'), this);
    this->boldAction->setCheckable(1);
    my $pixmap = Qt::Pixmap(':/images/bold.png');
    this->boldAction->setIcon(Qt::Icon($pixmap));
    this->boldAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+B')));
    this->connect(this->boldAction, SIGNAL 'triggered()',
            this, SLOT 'handleFontChange()');

    this->{italicAction} = Qt::Action(Qt::Icon(':/images/italic.png'),
                               this->tr('Italic'), this);
    this->italicAction->setCheckable(1);
    this->italicAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+I')));
    this->connect(this->italicAction, SIGNAL 'triggered()',
            this, SLOT 'handleFontChange()');

    this->{underlineAction} = Qt::Action(Qt::Icon(':/images/underline.png'),
                                  this->tr('Underline'), this);
    this->underlineAction->setCheckable(1);
    this->underlineAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+U')));
    this->connect(this->underlineAction, SIGNAL 'triggered()',
            this, SLOT 'handleFontChange()');

    this->{aboutAction} = Qt::Action(this->tr('A&bout'), this);
    this->aboutAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+B')));
    this->connect(this->aboutAction, SIGNAL 'triggered()',
            this, SLOT 'about()');
}

# [24]
sub createMenus
{
    this->{fileMenu} = this->menuBar()->addMenu(this->tr('&File'));
    this->fileMenu->addAction(this->exitAction);

    this->{itemMenu} = this->menuBar()->addMenu(this->tr('&Item'));
    this->itemMenu->addAction(this->deleteAction);
    this->itemMenu->addSeparator();
    this->itemMenu->addAction(this->toFrontAction);
    this->itemMenu->addAction(this->sendBackAction);

    this->{aboutMenu} = this->menuBar()->addMenu(this->tr('&Help'));
    this->aboutMenu->addAction(this->aboutAction);
}
# [24]

# [25]
sub createToolbars
{
# [25]
    this->{editToolBar} = this->addToolBar(this->tr('Edit'));
    this->editToolBar->addAction(this->deleteAction);
    this->editToolBar->addAction(this->toFrontAction);
    this->editToolBar->addAction(this->sendBackAction);

    this->{fontCombo} = Qt::FontComboBox();
    this->{fontSizeCombo} = Qt::ComboBox();
    this->connect(this->fontCombo, SIGNAL 'currentFontChanged(QFont)',
            this, SLOT 'currentFontChanged(QFont)');

    this->{fontSizeCombo} = Qt::ComboBox();
    this->fontSizeCombo->setEditable(1);
    for (my $i = 8; $i < 30; $i = $i + 2) {
        fontSizeCombo->addItem($i);
    }
    my $validator = Qt::IntValidator(2, 64, this);
    this->fontSizeCombo->setValidator($validator);
    this->connect(this->fontSizeCombo, SIGNAL 'currentIndexChanged(QString)',
            this, SLOT 'fontSizeChanged(QString)');

    this->{fontColorToolButton} = Qt::ToolButton();
    this->fontColorToolButton->setPopupMode(Qt::ToolButton::MenuButtonPopup());
    this->fontColorToolButton->setMenu(this->createColorMenu(SLOT 'textColorChanged()',
                                                 Qt::black()));
    this->{textAction} = this->fontColorToolButton->menu()->defaultAction();
    this->fontColorToolButton->setIcon(this->createColorToolButtonIcon(
        ':/images/textpointer.png', Qt::black()));
    this->fontColorToolButton->setAutoFillBackground(1);
    this->connect(this->fontColorToolButton, SIGNAL 'clicked()',
            this, SLOT 'textButtonTriggered()');

# [26]
    this->{fillColorToolButton} = Qt::ToolButton();
    this->fillColorToolButton->setPopupMode(Qt::ToolButton::MenuButtonPopup());
    this->fillColorToolButton->setMenu(this->createColorMenu(SLOT 'itemColorChanged()',
                         Qt::white()));
    this->{fillAction} = this->fillColorToolButton->menu()->defaultAction();
    this->fillColorToolButton->setIcon(this->createColorToolButtonIcon(
        ':/images/floodfill.png', Qt::white()));
    this->connect(this->fillColorToolButton, SIGNAL 'clicked()',
            this, SLOT 'fillButtonTriggered()');
# [26]

    this->{lineColorToolButton} = Qt::ToolButton();
    this->lineColorToolButton->setPopupMode(Qt::ToolButton::MenuButtonPopup());
    this->lineColorToolButton->setMenu(this->createColorMenu(SLOT 'lineColorChanged()',
                                 Qt::black()));
    this->{lineAction} = this->lineColorToolButton->menu()->defaultAction();
    this->lineColorToolButton->setIcon(this->createColorToolButtonIcon(
        ':/images/linecolor.png', Qt::black()));
    this->connect(this->lineColorToolButton, SIGNAL 'clicked()',
            this, SLOT 'lineButtonTriggered()');

    this->{textToolBar} = this->addToolBar(this->tr('Font'));
    this->textToolBar->addWidget(this->fontCombo);
    this->textToolBar->addWidget(this->fontSizeCombo);
    this->textToolBar->addAction(this->boldAction);
    this->textToolBar->addAction(this->italicAction);
    this->textToolBar->addAction(this->underlineAction);

    this->{colorToolBar} = this->addToolBar(this->tr('Color'));
    this->colorToolBar->addWidget(this->fontColorToolButton);
    this->colorToolBar->addWidget(this->fillColorToolButton);
    this->colorToolBar->addWidget(this->lineColorToolButton);

    my $pointerButton = Qt::ToolButton();
    $pointerButton->setCheckable(1);
    $pointerButton->setChecked(1);
    $pointerButton->setIcon(Qt::Icon(':/images/pointer.png'));
    my $linePointerButton = Qt::ToolButton();
    $linePointerButton->setCheckable(1);
    $linePointerButton->setIcon(Qt::Icon(':/images/linepointer.png'));

    this->{pointerTypeGroup} = Qt::ButtonGroup();
    this->pointerTypeGroup->addButton($pointerButton, DiagramScene::MoveItem);
    this->pointerTypeGroup->addButton($linePointerButton,
                                DiagramScene::InsertLine);
    this->connect(this->pointerTypeGroup, SIGNAL 'buttonClicked(int)',
            this, SLOT 'pointerGroupClicked(int)');

    this->{sceneScaleCombo} = Qt::ComboBox();
    my @scales = (this->tr('50%'), this->tr('75%'), this->tr('100%'), this->tr('125%'), this->tr('150%'));
    this->sceneScaleCombo->addItems(\@scales);
    this->sceneScaleCombo->setCurrentIndex(2);
    this->connect(this->sceneScaleCombo, SIGNAL 'currentIndexChanged(QString)',
            this, SLOT 'sceneScaleChanged(QString)');

    this->{pointerToolbar} = this->addToolBar(this->tr('Pointer type'));
    this->pointerToolbar->addWidget($pointerButton);
    this->pointerToolbar->addWidget($linePointerButton);
    this->pointerToolbar->addWidget(this->sceneScaleCombo);
# [27]
}
# [27]

# [28]
sub createBackgroundCellWidget
{
    my ($text, $image) = @_;
    my $button = Qt::ToolButton();
    $button->setText($text);
    $button->setIcon(Qt::Icon($image));
    $button->setIconSize(Qt::Size(50, 50));
    $button->setCheckable(1);
    this->backgroundButtonGroup->addButton($button);

    my $layout = Qt::GridLayout();
    $layout->addWidget($button, 0, 0, Qt::AlignHCenter());
    $layout->addWidget(Qt::Label($text), 1, 0, Qt::AlignCenter());

    my $widget = Qt::Widget();
    $widget->setLayout($layout);

    return $widget;
}
# [28]

# [29]
sub createCellWidget
{
    my ($text, $type) = @_;

    my $item = DiagramItem($type, this->itemMenu);
    my $icon = Qt::Icon($item->image());

    my $button = Qt::ToolButton();
    $button->setIcon($icon);
    $button->setIconSize(Qt::Size(50, 50));
    $button->setCheckable(1);
    this->buttonGroup->addButton($button, $type);

    my $layout = Qt::GridLayout();
    $layout->addWidget($button, 0, 0, Qt::AlignHCenter());
    $layout->addWidget(Qt::Label($text), 1, 0, Qt::AlignCenter());

    my $widget = Qt::Widget();
    $widget->setLayout($layout);

    return $widget;
}
# [29]

# [30]
sub createColorMenu
{
    my ($slot, $defaultColor) = @_;
    my @colors = ( Qt::black(), Qt::white(), Qt::red(), Qt::blue(), Qt::yellow() );
    my @names = ( this->tr('black'), this->tr('white'), this->tr('red'), this->tr('blue'),
        this->tr('yellow') );

    my $colorMenu = Qt::Menu();
    for (my $i = 0; $i < @colors; ++$i) {
        my $action = Qt::Action($names[$i], this);
        $action->setData(Qt::Variant($colors[$i]));
        $action->setIcon(this->createColorIcon($colors[$i]));
        this->connect($action, SIGNAL 'triggered()',
                this, $slot);
        $colorMenu->addAction($action);
        if ($colors[$i] == $defaultColor) {
            $colorMenu->setDefaultAction($action);
        }
    }
    return $colorMenu;
}
# [30]

# [31]
sub createColorToolButtonIcon
{
    my ($imageFile, $color) = @_;
    my $pixmap = Qt::Pixmap(50, 80);
    $pixmap->fill(Qt::Color(Qt::transparent()));
    my $painter = Qt::Painter($pixmap);
    my $image = Qt::Pixmap($imageFile);
    my $target = Qt::Rect(0, 0, 50, 60);
    my $source = Qt::Rect(0, 0, 42, 42);
    $painter->fillRect(Qt::Rect(0, 60, 50, 80), $color);
    $painter->drawPixmap($target, $image, $source);

    return Qt::Icon($pixmap);
}
# [31]

# [32]
sub createColorIcon
{
    my ($color) = @_;
    my $pixmap = Qt::Pixmap(20, 20);
    my $painter = Qt::Painter($pixmap);
    $painter->setPen(Qt::NoPen());
    $painter->fillRect(Qt::Rect(0, 0, 20, 20), $color);

    return Qt::Icon($pixmap);
}
# [32]

1;
