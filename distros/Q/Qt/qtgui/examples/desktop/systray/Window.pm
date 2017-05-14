package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    setIcon => ['int'],
    iconActivated => ['QSystemTrayIcon::ActivationReason'],
    showMessage => [],
    messageClicked => [];

sub iconGroupBox() {
    return this->{iconGroupBox};
}

sub setIconGroupBox($) {
    return this->{iconGroupBox} = shift;
}

sub iconLabel() {
    return this->{iconLabel};
}

sub setIconLabel($) {
    return this->{iconLabel} = shift;
}

sub iconComboBox() {
    return this->{iconComboBox};
}

sub setIconComboBox($) {
    return this->{iconComboBox} = shift;
}

sub showIconCheckBox() {
    return this->{showIconCheckBox};
}

sub setShowIconCheckBox($) {
    return this->{showIconCheckBox} = shift;
}

sub messageGroupBox() {
    return this->{messageGroupBox};
}

sub setMessageGroupBox($) {
    return this->{messageGroupBox} = shift;
}

sub typeLabel() {
    return this->{typeLabel};
}

sub setTypeLabel($) {
    return this->{typeLabel} = shift;
}

sub durationLabel() {
    return this->{durationLabel};
}

sub setDurationLabel($) {
    return this->{durationLabel} = shift;
}

sub durationWarningLabel() {
    return this->{durationWarningLabel};
}

sub setDurationWarningLabel($) {
    return this->{durationWarningLabel} = shift;
}

sub titleLabel() {
    return this->{titleLabel};
}

sub setTitleLabel($) {
    return this->{titleLabel} = shift;
}

sub bodyLabel() {
    return this->{bodyLabel};
}

sub setBodyLabel($) {
    return this->{bodyLabel} = shift;
}

sub typeComboBox() {
    return this->{typeComboBox};
}

sub setTypeComboBox($) {
    return this->{typeComboBox} = shift;
}

sub durationSpinBox() {
    return this->{durationSpinBox};
}

sub setDurationSpinBox($) {
    return this->{durationSpinBox} = shift;
}

sub titleEdit() {
    return this->{titleEdit};
}

sub setTitleEdit($) {
    return this->{titleEdit} = shift;
}

sub bodyEdit() {
    return this->{bodyEdit};
}

sub setBodyEdit($) {
    return this->{bodyEdit} = shift;
}

sub showMessageButton() {
    return this->{showMessageButton};
}

sub setShowMessageButton($) {
    return this->{showMessageButton} = shift;
}

sub minimizeAction() {
    return this->{minimizeAction};
}

sub setMinimizeAction($) {
    return this->{minimizeAction} = shift;
}

sub maximizeAction() {
    return this->{maximizeAction};
}

sub setMaximizeAction($) {
    return this->{maximizeAction} = shift;
}

sub restoreAction() {
    return this->{restoreAction};
}

sub setRestoreAction($) {
    return this->{restoreAction} = shift;
}

sub quitAction() {
    return this->{quitAction};
}

sub setQuitAction($) {
    return this->{quitAction} = shift;
}

sub trayIcon() {
    return this->{trayIcon};
}

sub setTrayIcon($) {
    return this->{trayIcon} = shift;
}

sub trayIconMenu() {
    return this->{trayIconMenu};
}

sub setTrayIconMenu($) {
    return this->{trayIconMenu} = shift;
}
# [0]

# [0]
sub NEW
{
    my ( $class ) = @_;
    $class->SUPER::NEW();
    this->createIconGroupBox();
    this->createMessageGroupBox();

    this->iconLabel->setMinimumWidth(this->durationLabel->sizeHint()->width());

    this->createActions();
    this->createTrayIcon();

    this->connect(this->showMessageButton, SIGNAL 'clicked()', this, SLOT 'showMessage()');
    this->connect(this->showIconCheckBox, SIGNAL 'toggled(bool)',
            this->trayIcon, SLOT 'setVisible(bool)');
    this->connect(this->iconComboBox, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'setIcon(int)');
    this->connect(this->trayIcon, SIGNAL 'messageClicked()', this, SLOT 'messageClicked()');
    this->connect(this->trayIcon, SIGNAL 'activated(QSystemTrayIcon::ActivationReason)',
            this, SLOT 'iconActivated(QSystemTrayIcon::ActivationReason)');

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget(this->iconGroupBox);
    $mainLayout->addWidget(this->messageGroupBox);
    this->setLayout($mainLayout);

    this->iconComboBox->setCurrentIndex(1);
    this->trayIcon->show();

    this->setWindowTitle(this->tr('Systray'));
    this->resize(400, 300);
}
# [0]

# [1]
sub setVisible
{
    my ($visible) = @_;
    this->minimizeAction->setEnabled($visible);
    this->maximizeAction->setEnabled(!this->isMaximized());
    this->restoreAction->setEnabled(this->isMaximized() || !$visible);
    this->SUPER::setVisible($visible);
}
# [1]

# [2]
sub closeEvent
{
    my ($event) = @_;
    if (this->trayIcon->isVisible()) {
        Qt::MessageBox::information(this, this->tr('Systray'),
                                 this->tr('The program will keep running in the ' .
                                    'system tray. To terminate the program, ' .
                                    'choose <b>Quit</b> in the context menu ' .
                                    'of the system tray entry.'));
        this->hide();
        $event->ignore();
    }
}
# [2]

# [3]
sub setIcon
{
    my ($index) = @_;
    my $icon = this->iconComboBox->itemIcon($index);
    this->trayIcon->setIcon($icon);
    this->setWindowIcon($icon);

    this->trayIcon->setToolTip(this->iconComboBox->itemText($index));
}
# [3]

# [4]
sub iconActivated
{
    my ($reason) = @_;
    if ($reason == Qt::SystemTrayIcon::Trigger() ||
        $reason == Qt::SystemTrayIcon::DoubleClick()) {
        this->iconComboBox->setCurrentIndex((this->iconComboBox->currentIndex() + 1)
                                      % this->iconComboBox->count());
    }
    elsif ($reason == Qt::SystemTrayIcon::MiddleClick()) {
        this->showMessage();
    }
}
# [4]

# [5]
sub showMessage
{
    my $icon = this->typeComboBox->itemData(this->typeComboBox->currentIndex())->toInt();
    this->trayIcon->showMessage(this->titleEdit->text(), this->bodyEdit->toPlainText(), $icon,
                          this->durationSpinBox->value() * 1000);
}
# [5]

# [6]
sub messageClicked
{
    Qt::MessageBox::information(undef, this->tr('Systray'),
                             this->tr("Sorry, I already gave what help I could.\n" .
                                'Maybe you should try asking a human?'));
}
# [6]

sub createIconGroupBox
{
    this->setIconGroupBox(Qt::GroupBox(this->tr('Tray Icon')));

    this->setIconLabel(Qt::Label('Icon:'));

    this->setIconComboBox(Qt::ComboBox());
    this->iconComboBox->addItem(Qt::Icon('images/bad.svg'), this->tr('Bad'));
    this->iconComboBox->addItem(Qt::Icon('images/heart.svg'), this->tr('Heart'));
    this->iconComboBox->addItem(Qt::Icon('images/trash.svg'), this->tr('Trash'));

    this->setShowIconCheckBox(Qt::CheckBox(this->tr('Show icon')));
    this->showIconCheckBox->setChecked(1);

    my $iconLayout = Qt::HBoxLayout();
    $iconLayout->addWidget(this->iconLabel);
    $iconLayout->addWidget(this->iconComboBox);
    $iconLayout->addStretch();
    $iconLayout->addWidget(this->showIconCheckBox);
    this->iconGroupBox->setLayout($iconLayout);
}

sub createMessageGroupBox
{
    this->setMessageGroupBox(Qt::GroupBox(this->tr('Balloon Message')));

    this->setTypeLabel(Qt::Label(this->tr('Type:')));

    this->setTypeComboBox(Qt::ComboBox());
    this->typeComboBox->addItem(this->tr('None'), Qt::Variant(Qt::Int(${Qt::SystemTrayIcon::NoIcon()})));
    this->typeComboBox->addItem(this->style()->standardIcon(
            Qt::Style::SP_MessageBoxInformation()), this->tr('Information'),
            Qt::Variant(Qt::Int(${Qt::SystemTrayIcon::Information()})));
    this->typeComboBox->addItem(this->style()->standardIcon(
            Qt::Style::SP_MessageBoxWarning()), this->tr('Warning'),
            Qt::Variant(Qt::Int(${Qt::SystemTrayIcon::Warning()})));
    this->typeComboBox->addItem(this->style()->standardIcon(
            Qt::Style::SP_MessageBoxCritical()), this->tr('Critical'),
            Qt::Variant(Qt::Int(${Qt::SystemTrayIcon::Critical()})));
    this->typeComboBox->setCurrentIndex(1);

    this->setDurationLabel(Qt::Label(this->tr('Duration:')));

    this->setDurationSpinBox(Qt::SpinBox());
    this->durationSpinBox->setRange(5, 60);
    this->durationSpinBox->setSuffix(' s');
    this->durationSpinBox->setValue(15);

    this->setDurationWarningLabel(Qt::Label(this->tr('(some systems might ignore this '.
                                         'hint)')));
    this->durationWarningLabel->setIndent(10);

    this->setTitleLabel(Qt::Label(this->tr('Title:')));

    this->setTitleEdit(Qt::LineEdit(this->tr('Cannot connect to network')));

    this->setBodyLabel(Qt::Label(this->tr('Body:')));

    this->setBodyEdit(Qt::TextEdit());
    this->bodyEdit->setPlainText(this->tr('Don\'t believe me. Honestly, I don\'t have a ' .
                              "clue.\nClick this balloon for details."));

    this->setShowMessageButton(Qt::PushButton(this->tr('Show Message')));
    this->showMessageButton->setDefault(1);

    my $messageLayout = Qt::GridLayout();
    $messageLayout->addWidget(this->typeLabel, 0, 0);
    $messageLayout->addWidget(this->typeComboBox, 0, 1, 1, 2);
    $messageLayout->addWidget(this->durationLabel, 1, 0);
    $messageLayout->addWidget(this->durationSpinBox, 1, 1);
    $messageLayout->addWidget(this->durationWarningLabel, 1, 2, 1, 3);
    $messageLayout->addWidget(this->titleLabel, 2, 0);
    $messageLayout->addWidget(this->titleEdit, 2, 1, 1, 4);
    $messageLayout->addWidget(this->bodyLabel, 3, 0);
    $messageLayout->addWidget(this->bodyEdit, 3, 1, 2, 4);
    $messageLayout->addWidget(this->showMessageButton, 5, 4);
    $messageLayout->setColumnStretch(3, 1);
    $messageLayout->setRowStretch(4, 1);
    this->messageGroupBox->setLayout($messageLayout);
}

sub createActions
{
    this->setMinimizeAction(Qt::Action(this->tr('Mi&nimize'), this));
    this->connect(this->minimizeAction, SIGNAL 'triggered()', this, SLOT 'hide()');

    this->setMaximizeAction(Qt::Action(this->tr('Ma&ximize'), this));
    this->connect(this->maximizeAction, SIGNAL 'triggered()', this, SLOT 'showMaximized()');

    this->setRestoreAction(Qt::Action(this->tr('&Restore'), this));
    this->connect(this->restoreAction, SIGNAL 'triggered()', this, SLOT 'showNormal()');

    this->setQuitAction(Qt::Action(this->tr('&Quit'), this));
    this->connect(this->quitAction, SIGNAL 'triggered()', qApp, SLOT 'quit()');
}

sub createTrayIcon
{
    this->setTrayIconMenu(Qt::Menu(this));
    this->trayIconMenu->addAction(this->minimizeAction);
    this->trayIconMenu->addAction(this->maximizeAction);
    this->trayIconMenu->addAction(this->restoreAction);
    this->trayIconMenu->addSeparator();
    this->trayIconMenu->addAction(this->quitAction);

    this->setTrayIcon(Qt::SystemTrayIcon(this));
    trayIcon->setContextMenu(this->trayIconMenu);
}

1;
