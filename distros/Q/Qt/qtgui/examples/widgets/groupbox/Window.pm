package Window;

# [0]
use QtCore4::isa qw( Qt::Widget );
# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    my $grid = Qt::GridLayout();
    $grid->addWidget(this->createFirstExclusiveGroup(), 0, 0);
    $grid->addWidget(this->createSecondExclusiveGroup(), 1, 0);
    $grid->addWidget(this->createNonExclusiveGroup(), 0, 1);
    $grid->addWidget(this->createPushButtonGroup(), 1, 1);
    this->setLayout($grid);

    this->setWindowTitle(this->tr('Group Boxes'));
    this->resize(480, 320);
}
# [0]

# [1]
sub createFirstExclusiveGroup {
# [2]
    my $groupBox = Qt::GroupBox(this->tr('Exclusive Radio Buttons'));

    my $radio1 = Qt::RadioButton(this->tr('&Radio button 1'));
    my $radio2 = Qt::RadioButton(this->tr('R&adio button 2'));
    my $radio3 = Qt::RadioButton(this->tr('Ra&dio button 3'));

    $radio1->setChecked(1);
# [1] //! [3]

    my $vbox = Qt::VBoxLayout();
    $vbox->addWidget($radio1);
    $vbox->addWidget($radio2);
    $vbox->addWidget($radio3);
    $vbox->addStretch(1);
    $groupBox->setLayout($vbox);
# [2]

    return $groupBox;
}
# [3]

# [4]
sub createSecondExclusiveGroup {
    my $groupBox = Qt::GroupBox(this->tr('E&xclusive Radio Buttons'));
    $groupBox->setCheckable(1);
    $groupBox->setChecked(0);
# [4]

# [5]
    my $radio1 = Qt::RadioButton(this->tr('Rad&io button 1'));
    my $radio2 = Qt::RadioButton(this->tr('Radi&o button 2'));
    my $radio3 = Qt::RadioButton(this->tr('Radio &button 3'));
    $radio1->setChecked(1);
    my $checkBox = Qt::CheckBox(this->tr('Ind&ependent checkbox'));
    $checkBox->setChecked(1);
# [5]

# [6]
    my $vbox = Qt::VBoxLayout();
    $vbox->addWidget($radio1);
    $vbox->addWidget($radio2);
    $vbox->addWidget($radio3);
    $vbox->addWidget($checkBox);
    $vbox->addStretch(1);
    $groupBox->setLayout($vbox);

    return $groupBox;
}
# [6]

# [7]
sub createNonExclusiveGroup {
    my $groupBox = Qt::GroupBox(this->tr('Non-Exclusive Checkboxes'));
    $groupBox->setFlat(1);
# [7]

# [8]
    my $checkBox1 = Qt::CheckBox(this->tr('&Checkbox 1'));
    my $checkBox2 = Qt::CheckBox(this->tr('C&heckbox 2'));
    $checkBox2->setChecked(1);
    my $tristateBox = Qt::CheckBox(this->tr('Tri-&state button'));
    $tristateBox->setTristate(1);
# [8]
    $tristateBox->setCheckState(Qt::PartiallyChecked());

# [9]
    my $vbox = Qt::VBoxLayout();
    $vbox->addWidget($checkBox1);
    $vbox->addWidget($checkBox2);
    $vbox->addWidget($tristateBox);
    $vbox->addStretch(1);
    $groupBox->setLayout($vbox);

    return $groupBox;
}
# [9]

# [10]
sub createPushButtonGroup {
    my $groupBox = Qt::GroupBox(this->tr('&Push Buttons'));
    $groupBox->setCheckable(1);
    $groupBox->setChecked(1);
# [10]

# [11]
    my $pushButton = Qt::PushButton(this->tr('&Normal Button'));
    my $toggleButton = Qt::PushButton(this->tr('&Toggle Button'));
    $toggleButton->setCheckable(1);
    $toggleButton->setChecked(1);
    my $flatButton = Qt::PushButton(this->tr('&Flat Button'));
    $flatButton->setFlat(1);
# [11]

# [12]
    my $popupButton = Qt::PushButton(this->tr('Pop&up Button'));
    my $menu = Qt::Menu(this);
    $menu->addAction(this->tr('&First Item'));
    $menu->addAction(this->tr('&Second Item'));
    $menu->addAction(this->tr('&Third Item'));
    $menu->addAction(this->tr('F&ourth Item'));
    $popupButton->setMenu($menu);
# [12]

    my $newAction = $menu->addAction(this->tr('Submenu'));
    my $subMenu = Qt::Menu(this->tr('Popup Submenu'));
    $subMenu->addAction(this->tr('Item 1'));
    $subMenu->addAction(this->tr('Item 2'));
    $subMenu->addAction(this->tr('Item 3'));
    $newAction->setMenu($subMenu);

# [13]
    my $vbox = Qt::VBoxLayout();
    $vbox->addWidget($pushButton);
    $vbox->addWidget($toggleButton);
    $vbox->addWidget($flatButton);
    $vbox->addWidget($popupButton);
    $vbox->addStretch(1);
    $groupBox->setLayout($vbox);

    return $groupBox;
}
# [13]

1;
